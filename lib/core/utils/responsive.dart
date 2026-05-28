import 'package:flutter/widgets.dart';

// Base design: iPhone 14 (390×844 logical pixels).
const double _baseWidth = 390.0;
const double _baseHeight = 844.0;

extension ResponsiveContext on BuildContext {
  double get _sw => MediaQuery.sizeOf(this).width;
  double get _sh => MediaQuery.sizeOf(this).height;

  bool get isPhone => _sw < 600;
  bool get isTablet => _sw >= 600 && _sw < 900;
  bool get isDesktop => _sw >= 900;

  /// Scale a font size proportionally to screen width (phone range: ±15%).
  double sp(double size) => size * (_sw / _baseWidth).clamp(0.85, 1.15);

  /// Scale a horizontal dimension proportionally to screen width.
  double sw(double size) => size * (_sw / _baseWidth).clamp(0.85, 1.15);

  /// Scale a vertical dimension proportionally to screen height.
  double sh(double size) => size * (_sh / _baseHeight).clamp(0.85, 1.15);
}
