import 'package:flutter/material.dart';

/// Warm-minimal shadows — barely there. The design leans on hairline
/// borders and subtle warm-ink shadows rather than drop shadows.
class PayPactShadows {
  // Tinted with the warm-ink color (#1F1B16) at low alpha.
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A1F1B16),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x141F1B16),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1F1F1B16),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  // Clay accent glow — used very sparingly.
  static const List<BoxShadow> accent = [
    BoxShadow(
      color: Color(0x33B05A3C),
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
  ];

  // Dark
  static const List<BoxShadow> smDark = [
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: Color(0x80000000),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const List<BoxShadow> lgDark = [
    BoxShadow(
      color: Color(0x99000000),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}
