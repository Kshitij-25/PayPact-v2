import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Bottom sheet that renders a QR code for a Paypact group invite link.
/// The QR encodes a `https://paypact-fec8e.web.app/invite/<code>` link which:
///   • Opens the app directly via App Links (Android) / Universal Links (iOS)
///     when the app is installed.
///   • Falls back to the hosted web landing page in the browser when not installed.
class QrInviteSheet extends StatelessWidget {
  const QrInviteSheet({
    super.key,
    required this.groupName,
    required this.inviteCode,
    required this.inviteLink,
  });

  final String groupName;
  final String inviteCode;
  final String inviteLink; // paypact://invite/<code>

  static Future<void> show(
    BuildContext context, {
    required String groupName,
    required String inviteCode,
    required String inviteLink,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QrInviteSheet(
        groupName: groupName,
        inviteCode: inviteCode,
        inviteLink: inviteLink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrFg = isDark ? Colors.white : Colors.black;
    final qrBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header ────────────────────────────────────────────────
          const Text(
            'Invite to Group',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            groupName,
            style: const TextStyle(
                fontSize: 14, color: PaypactColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── QR Code ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: qrBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: inviteLink,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: qrBg,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: qrFg,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: qrFg,
                  ),
                  // Embed the Paypact "P" logo in the centre
                  embeddedImage: const AssetImage('assets/images/logo_qr.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(36, 36),
                  ),
                ),
                const SizedBox(height: 16),
                // Invite code pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: PaypactColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: PaypactColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        inviteCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: PaypactColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite code copied')),
                          );
                        },
                        child: const Icon(Icons.copy_rounded,
                            size: 16, color: PaypactColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan with Paypact to join instantly',
            style: TextStyle(fontSize: 12, color: PaypactColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied')),
                    );
                  },
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Share.share(
                    'Join my group "$groupName" on Paypact!\n\n'
                    'Tap the link or enter code $inviteCode:\n$inviteLink',
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaypactColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
