import 'package:flutter/material.dart';

/// Warm-minimal palette.
/// Light: bone/cream surfaces, warm near-black ink, single clay accent.
/// Dark : warm charcoal surfaces, bone ink, clay accent shifted warm.
class PayPactColors {
  // ── Accent (clay) ─────────────────────────────────────────────────────
  static const Color accent = Color(0xFFB05A3C); // clay
  static const Color accentSoft = Color(0xFFEDD9CF);
  static const Color accentInk = Color(0xFF7A3A24);
  static const Color accentDarkMode = Color(0xFFC77556);
  static const Color accentSoftDark = Color(0xFF3A2218);
  static const Color accentInkDark = Color(0xFFE6A48A);

  // Back-compat shims (kept so legacy widgets keep compiling).
  static const Color accentLight = accentSoft;
  static const Color accentDark = accentInk;
  static const Color navy = Color(0xFF1F1B16);
  static const Color navyCard = Color(0xFF2A241D);

  // ── Semantic — quiet earthy tones ─────────────────────────────────────
  static const Color positive = Color(0xFF5C7B5B); // sage
  static const Color positiveLt = Color(0xFFDEE6D7);
  static const Color negative = Color(0xFF9B4736); // muted terracotta
  static const Color negativeLt = Color(0xFFECD7D1);
  static const Color pending = Color(0xFF9A7530); // olive/amber
  static const Color pendingLt = Color(0xFFEDE3CC);
  static const Color info = Color(0xFF3C4A58);

  // Dark-mode semantic
  static const Color positiveDark = Color(0xFF7DA37C);
  static const Color positiveDarkLt = Color(0xFF1F2A20);
  static const Color negativeDark = Color(0xFFC46B59);
  static const Color negativeDarkLt = Color(0xFF2D1C18);
  static const Color pendingDark = Color(0xFFC29A4F);
  static const Color pendingDarkLt = Color(0xFF2A2317);

  // ── Light surfaces & ink ──────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF5F2EC); // bone
  static const Color surfaceLight = Color(0xFFFAF7F1); // paper / cards
  static const Color surface2Light = Color(0xFFEFEAE0); // raised
  static const Color surface3Light = Color(0xFFE8E1D2); // pressed
  static const Color borderLight = Color(0xFFE2DACA);
  static const Color borderStrongLight = Color(0xFFC9BFAA);
  static const Color textPrimaryLight = Color(0xFF1F1B16); // warm near-black
  static const Color textSecondaryLight = Color(0xFF6B6357);
  static const Color textTertiaryLight = Color(0xFFA39A8A);
  static const Color textDisabledLight = Color(0xFFC8BFAF);

  // ── Dark surfaces & ink ───────────────────────────────────────────────
  static const Color bgDark = Color(0xFF100D09);
  static const Color surfaceDark = Color(0xFF1A1612);
  static const Color surface2Dark = Color(0xFF221D17);
  static const Color surface3Dark = Color(0xFF2A241D);
  static const Color borderDark = Color(0xFF2E2820);
  static const Color borderStrongDark = Color(0xFF453C30);
  static const Color textPrimaryDark = Color(0xFFECE4D2);
  static const Color textSecondaryDark = Color(0xFF9C9385);
  static const Color textTertiaryDark = Color(0xFF6B6356);
  static const Color textDisabledDark = Color(0xFF3F3A30);
}
