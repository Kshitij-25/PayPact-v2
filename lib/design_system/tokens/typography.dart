import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm-minimal typography.
/// UI       — Geist (modern grotesk)
/// Numerals — Geist Mono with tabular figures
/// Accents  — Instrument Serif (italic, used sparingly for hero moments)
class PayPactTypography {
  static const _tabular = [FontFeature.tabularFigures()];

  // ── Display ──────────────────────────────────────────────────────────
  static TextStyle get displayXl => GoogleFonts.geist(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.03 * 36,
        height: 1.05,
      );

  static TextStyle get displayLg => GoogleFonts.geist(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.025 * 28,
        height: 1.1,
      );

  // ── Headings ─────────────────────────────────────────────────────────
  static TextStyle get headingXl => GoogleFonts.geist(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 22,
        height: 1.2,
      );

  static TextStyle get headingLg => GoogleFonts.geist(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015 * 18,
        height: 1.25,
      );

  static TextStyle get headingMd => GoogleFonts.geist(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 15,
        height: 1.3,
      );

  // ── Body ─────────────────────────────────────────────────────────────
  static TextStyle get bodyLg => GoogleFonts.geist(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get bodyMd => GoogleFonts.geist(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get bodySm => GoogleFonts.geist(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ── Labels / micro ───────────────────────────────────────────────────
  static TextStyle get label => GoogleFonts.geist(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08 * 11,
      );

  static TextStyle get micro => GoogleFonts.geist(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.3,
      );

  // ── Mono (amounts) ───────────────────────────────────────────────────
  static TextStyle get amountHero => GoogleFonts.geistMono(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.04 * 48,
        height: 1.0,
        fontFeatures: _tabular,
      );

  static TextStyle get amountXl => GoogleFonts.geistMono(
        fontSize: 40,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.03 * 40,
        fontFeatures: _tabular,
      );

  static TextStyle get amountLg => GoogleFonts.geistMono(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.02 * 22,
        fontFeatures: _tabular,
      );

  static TextStyle get amountMd => GoogleFonts.geistMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFeatures: _tabular,
      );

  static TextStyle get amountSm => GoogleFonts.geistMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFeatures: _tabular,
      );

  // ── Serif accent (hero moments) ──────────────────────────────────────
  static TextStyle get serifHero => GoogleFonts.instrumentSerif(
        fontSize: 52,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.03 * 52,
        height: 1.0,
      );

  static TextStyle get serifDisplay => GoogleFonts.instrumentSerif(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02 * 28,
      );

  // ── Back-compat aliases (kept so legacy widgets keep compiling) ──────
  static TextStyle get headingXl_ => headingXl;
  static TextStyle get monoLg => amountLg;
  static TextStyle get monoMd => amountMd;
}
