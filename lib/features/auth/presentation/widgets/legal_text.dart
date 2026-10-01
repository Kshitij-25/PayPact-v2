import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:paypact/core/constants/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

/// "…agree to our Terms and Privacy Policy…" with both names tappable.
class LegalText extends StatefulWidget {
  const LegalText({
    super.key,
    required this.prefix,
    this.termsLabel = 'Terms',
    this.privacyLabel = 'Privacy Policy',
    this.suffix = '.',
    this.conjunction = ' and ',
    required this.style,
    required this.linkStyle,
    this.textAlign = TextAlign.start,
  });
  final String prefix;
  final String termsLabel;
  final String privacyLabel;
  final String suffix;
  final String conjunction;
  final TextStyle style;
  final TextStyle linkStyle;
  final TextAlign textAlign;

  @override
  State<LegalText> createState() => _LegalTextState();
}

class _LegalTextState extends State<LegalText> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => _open(AppLinks.terms);
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => _open(AppLinks.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    messenger.showSnackBar(SnackBar(content: Text("Couldn't open $url")));
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: widget.style, children: [
        TextSpan(text: widget.prefix),
        TextSpan(
            text: widget.termsLabel,
            style: widget.linkStyle,
            recognizer: _terms),
        TextSpan(text: widget.conjunction),
        TextSpan(
            text: widget.privacyLabel,
            style: widget.linkStyle,
            recognizer: _privacy),
        TextSpan(text: widget.suffix),
      ]),
      textAlign: widget.textAlign,
    );
  }
}
