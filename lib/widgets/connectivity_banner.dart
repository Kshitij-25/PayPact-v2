import 'package:paypact/l10n/l10n.dart';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/typography.dart';

/// Whether a connectivity report means "no network at all".
bool isOffline(List<ConnectivityResult> results) =>
    results.isEmpty || results.every((r) => r == ConnectivityResult.none);

/// A slim banner shown while the device is offline. Firestore keeps working
/// from its cache and queues writes, so the banner explains what to expect
/// instead of leaving screens that wait on the server looking frozen.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({
    super.key,
    required this.child,
    this.connectivity,
    this.stream,
  });
  final Widget child;

  /// Injectable for tests.
  final Connectivity? connectivity;
  final Stream<List<ConnectivityResult>>? stream;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    final c = widget.connectivity ?? Connectivity();
    final stream = widget.stream ?? c.onConnectivityChanged;
    _sub = stream.listen((r) {
      if (mounted) setState(() => _offline = isOffline(r));
    }, onError: (_) {});
    if (widget.stream == null) {
      c.checkConnectivity().then((r) {
        if (mounted) setState(() => _offline = isOffline(r));
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _offline
              ? Material(
                  color: pt.negativeSoft,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 16, color: pt.negative),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.offlineBanner,
                            style: PayPactTypography.bodySm
                                .copyWith(color: pt.negative),
                          ),
                        ),
                      ]),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
