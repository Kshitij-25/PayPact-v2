import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  DeepLinkService();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  final _inviteCodeController = StreamController<String>.broadcast();

  Stream<String> get onInviteCodeReceived => _inviteCodeController.stream;

  Future<void> initialize() async {
    // Handle cold start — app was launched directly from the link
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        debugPrint('[DeepLink] Cold start URI: $initial');
        _handleLink(initial);
      }
    } catch (e) {
      debugPrint('[DeepLink] Cold start error: $e');
    }

    // Handle warm start — app was already running when link was opened
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[DeepLink] Warm start URI: $uri');
        _handleLink(uri);
      },
      onError: (e) => debugPrint('[DeepLink] Stream error: $e'),
    );
  }

  void _handleLink(Uri uri) {
    String? code;

    // paypact://invite/ABC123
    //   scheme = paypact, host = invite, pathSegments = ['ABC123']
    if (uri.scheme == 'paypact' && uri.host == 'invite') {
      code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    // https://paypact.app/invite/ABC123
    //   pathSegments = ['invite', 'ABC123']
    else if (uri.scheme == 'https' &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'invite') {
      code = uri.pathSegments[1];
    }

    if (code != null && code.isNotEmpty) {
      debugPrint('[DeepLink] Invite code extracted: $code');
      _inviteCodeController.add(code);
    } else {
      debugPrint('[DeepLink] Unrecognised URI — ignored: $uri');
    }
  }

  void dispose() {
    _sub?.cancel();
    _inviteCodeController.close();
  }
}
