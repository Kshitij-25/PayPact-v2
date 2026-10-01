import 'package:paypact/core/utils/invite_code.dart';

/// Where shareable links point. The host must match the Android App Links /
/// iOS associated-domains config and the `/invite/**` hosting rewrite.
class AppLinks {
  AppLinks._();

  static const host = 'paypact-fec8e.web.app';

  static String invite(String code) => 'https://$host/invite/$code';

  /// Hosted legal pages (web/legal/*.html).
  static const terms = 'https://$host/legal/terms.html';
  static const privacy = 'https://$host/legal/privacy.html';

  /// Extracts an invite code from any link we hand out:
  /// `https://<host>/invite/CODE`, `https://<host>/join/CODE`,
  /// `paypact://invite/CODE`, or a bare `/CODE`-style path.
  static String? inviteCodeFrom(Uri uri) {
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (uri.scheme == 'paypact' && uri.host == 'invite') {
      return segs.isEmpty ? null : normalizeInviteCode(segs.first);
    }
    if (segs.length == 2 && (segs[0] == 'invite' || segs[0] == 'join')) {
      return normalizeInviteCode(segs[1]);
    }
    return null;
  }
}
