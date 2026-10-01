import 'package:flutter/widgets.dart';
import 'package:paypact/l10n/app_localizations.dart';

export 'package:paypact/l10n/app_localizations.dart';

/// `context.l10n.navHome` — the app's translated strings.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
