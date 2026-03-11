import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/group/presentation/bloc/group_bloc.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _processing = false; // prevent double-scans
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _ctrl.start();
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  // ── Scan processing ────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      final code = _extractInviteCode(raw);
      if (code != null) {
        _processing = true;
        _ctrl.stop();
        _handleInviteCode(code);
        return;
      }
    }
  }

  /// Returns the invite code if [raw] is a valid Paypact invite URI, null otherwise.
  /// Handles:
  ///   paypact://invite/<code>
  ///   https://paypact-fec8e.web.app/invite/<code>
  String? _extractInviteCode(String raw) {
    try {
      final uri = Uri.parse(raw);

      // Custom scheme: paypact://invite/ABC123
      if (uri.scheme == 'paypact' && uri.host == 'invite') {
        final code = uri.pathSegments.firstOrNull;
        if (code != null && code.isNotEmpty) return code;
      }

      // HTTPS Firebase Hosting: https://paypact-fec8e.web.app/invite/ABC123
      if (uri.scheme == 'https' &&
          uri.host == 'paypact-fec8e.web.app' &&
          uri.pathSegments.length >= 2 &&
          uri.pathSegments[0] == 'invite') {
        final code = uri.pathSegments[1];
        if (code.isNotEmpty) return code;
      }
    } catch (_) {}
    return null;
  }

  void _handleInviteCode(String code) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      _showError('You must be signed in to join a group.');
      return;
    }

    _showJoinConfirmation(code, user);
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showJoinConfirmation(String code, UserEntity user) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Join Group?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PaypactColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.qr_code_rounded,
                    color: PaypactColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Invite code',
                          style: TextStyle(
                              fontSize: 11,
                              color: PaypactColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: PaypactColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            const Text(
              'You are about to join a new group. This will add you as a member.',
              style:
                  TextStyle(fontSize: 13, color: PaypactColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              _processing = false;
              _ctrl.start();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PaypactColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<GroupBloc>().add(
              GroupJoinRequested(inviteCode: code, user: user),
            );
        _listenAndNavigate();
      } else {
        _processing = false;
        _ctrl.start();
      }
    });
  }

  /// Listen to GroupBloc for success/failure then navigate home.
  void _listenAndNavigate() {
    late final StreamSubscription<GroupState> sub;
    sub = context.read<GroupBloc>().stream.listen((state) {
      if (state.status == GroupStatus.success) {
        sub.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('🎉 You have joined the group!'),
                backgroundColor: PaypactColors.secondary),
          );
          context.go('/');
        }
      } else if (state.status == GroupStatus.failure) {
        sub.cancel();
        if (mounted) _showError(state.errorMessage ?? 'Failed to join group.');
      }
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Could not join'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processing = false;
              _ctrl.start();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title:
            const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        actions: [
          // Torch toggle
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            tooltip: 'Toggle torch',
            onPressed: () {
              _ctrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          // Flip camera
          IconButton(
            icon:
                const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
            tooltip: 'Flip camera',
            onPressed: () => _ctrl.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Live camera preview ──────────────────────────────────
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // ── Dimmed overlay with cut-out window ───────────────────
          _ScanOverlay(),

          // ── Bottom hint card ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Point at a Paypact group QR code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The QR code can be found in\nGroup Settings → Invite → Show QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  // Manual code entry fallback
                  OutlinedButton.icon(
                    onPressed: _showManualEntry,
                    icon: const Icon(Icons.keyboard_alt_outlined,
                        size: 18, color: Colors.white),
                    label: const Text('Enter code manually',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Processing spinner ────────────────────────────────────
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: PaypactColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  // ── Manual code entry ──────────────────────────────────────────────────────

  void _showManualEntry() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter Invite Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Paste or type the code shared by your group admin',
                style:
                    TextStyle(fontSize: 13, color: PaypactColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  hintText: 'ABC12345',
                  hintStyle: const TextStyle(
                      color: PaypactColors.textSecondary, letterSpacing: 2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final code = ctrl.text.trim().toUpperCase();
                    if (code.isEmpty) return;
                    Navigator.pop(ctx);
                    _processing = true;
                    _handleInviteCode(code);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaypactColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Join Group',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan-window overlay
// ─────────────────────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _OverlayPainter(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  static const _windowSize = 260.0;
  static const _cornerRadius = 16.0;
  static const _cornerLength = 32.0;
  static const _cornerStroke = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 40; // slightly above centre
    final left = cx - _windowSize / 2;
    final top = cy - _windowSize / 2;
    final right = cx + _windowSize / 2;
    final bottom = cy + _windowSize / 2;
    final window = RRect.fromLTRBR(
      left,
      top,
      right,
      bottom,
      const Radius.circular(_cornerRadius),
    );

    // Dim everything outside the window
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(window);
    canvas.drawPath(
        Path.combine(PathOperation.difference, full, hole), dimPaint);

    // Animated corner brackets
    final cornerPaint = Paint()
      ..color = PaypactColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    _drawCorner(canvas, cornerPaint, left, top, 1, 1);
    // Top-right
    _drawCorner(canvas, cornerPaint, right, top, -1, 1);
    // Bottom-left
    _drawCorner(canvas, cornerPaint, left, bottom, 1, -1);
    // Bottom-right
    _drawCorner(canvas, cornerPaint, right, bottom, -1, -1);

    // Subtle scan line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          PaypactColors.primary.withOpacity(0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(left, top, _windowSize, 2));
    canvas.drawLine(Offset(left, cy), Offset(right, cy), linePaint);
  }

  void _drawCorner(
      Canvas canvas, Paint paint, double x, double y, double dx, double dy) {
    final path = Path()
      ..moveTo(x + dx * _cornerRadius, y)
      ..lineTo(x + dx * _cornerLength, y)
      ..moveTo(x, y + dy * _cornerRadius)
      ..lineTo(x, y + dy * _cornerLength);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
