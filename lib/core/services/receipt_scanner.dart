import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// What we could read off a receipt. Every field is optional — OCR is a
/// convenience that pre-fills the form, never a source of truth.
class ReceiptScan {
  const ReceiptScan({this.total, this.merchant, this.date, this.rawText = ''});
  final double? total;
  final String? merchant;
  final DateTime? date;
  final String rawText;

  bool get isEmpty => total == null && merchant == null && date == null;
}

// ── Parsing (pure; unit-tested) ──────────────────────────────────────────────

final _amountRe = RegExp(r'(?<![\d.,])(\d{1,3}(?:[ ,.]\d{3})+|\d+)[.,](\d{2})(?!\d)');
final _totalKeyword = RegExp(
    r'(grand\s*total|total\s*(amount|due|payable|bill)?|amount\s*(due|payable|paid)|balance\s*due|net\s*(amount|total|payable)|to\s*pay|bill\s*amount|amt\s*payable)',
    caseSensitive: false);
final _notATotal = RegExp(
    r'(sub\s*-?\s*total|total\s*(tax|gst|vat|items?|qty|quantity|discount|savings?|saved)|tax\s*total|cgst|sgst|igst)',
    caseSensitive: false);

/// All money-looking numbers on a line ("1,234.50", "12.00", "9,99").
List<double> _amountsIn(String line) {
  final out = <double>[];
  for (final m in _amountRe.allMatches(line)) {
    final whole = m.group(1)!.replaceAll(RegExp(r'[ ,.]'), '');
    final cents = m.group(2)!;
    final v = double.tryParse('$whole.$cents');
    if (v != null && v > 0) out.add(v);
  }
  return out;
}

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

DateTime? _plausible(int y, int m, int d, DateTime now) {
  if (y < 100) y += 2000;
  if (y < 2000 || m < 1 || m > 12 || d < 1 || d > 31) return null;
  final date = DateTime(y, m, d);
  if (date.month != m) return null; // e.g. 31 Feb
  if (date.isAfter(now.add(const Duration(days: 1)))) return null;
  return date;
}

DateTime? _findDate(String text, DateTime now) {
  // 2026-03-05
  final iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b').firstMatch(text);
  if (iso != null) {
    final d = _plausible(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!), now);
    if (d != null) return d;
  }
  // 05 Mar 2026 / 5 March, 2026
  final named = RegExp(
          r'\b(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?,?\s+(\d{2,4})\b',
          caseSensitive: false)
      .firstMatch(text);
  if (named != null) {
    final d = _plausible(int.parse(named[3]!), _months[named[2]!.toLowerCase()]!,
        int.parse(named[1]!), now);
    if (d != null) return d;
  }
  // 05/03/2026, 5-3-26 — day first (the default where this app is used), but
  // if the "month" can't be a month, it must be month-first.
  final slashed =
      RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b').firstMatch(text);
  if (slashed != null) {
    var a = int.parse(slashed[1]!), b = int.parse(slashed[2]!);
    final y = int.parse(slashed[3]!);
    final d = b > 12 ? _plausible(y, a, b, now) : _plausible(y, b, a, now);
    if (d != null) return d;
  }
  return null;
}

const _skipForMerchant = [
  'invoice', 'receipt', 'tax', 'gst', 'vat', 'bill no', 'bill#', 'tel', 'phone',
  'ph:', 'date', 'www', 'http', '@', 'thank', 'welcome', 'cashier', 'table',
  'order', 'gstin', 'cin', 'fssai', 'pan',
];

String? _findMerchant(List<String> lines) {
  for (final raw in lines.take(8)) {
    final line = raw.trim();
    final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
    if (letters < 3 || letters < line.length * 0.5) continue;
    final lower = line.toLowerCase();
    if (_skipForMerchant.any(lower.contains)) continue;
    return line.length > 40 ? line.substring(0, 40).trim() : line;
  }
  return null;
}

/// Pulls a total, a merchant name and a date out of raw receipt text.
ReceiptScan parseReceiptText(String text, {DateTime? now}) {
  final lines = text
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  // 1) Amounts on lines that say "total…" (but not "subtotal", "total tax"…);
  //    a lone keyword line takes the amount from the line below it.
  final keyed = <double>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!_totalKeyword.hasMatch(line) || _notATotal.hasMatch(line)) continue;
    var found = _amountsIn(line);
    if (found.isEmpty && i + 1 < lines.length) found = _amountsIn(lines[i + 1]);
    keyed.addAll(found);
  }
  // 2) Otherwise the biggest amount on the page is the best guess.
  final all = [for (final l in lines) ..._amountsIn(l)];
  double? total;
  if (keyed.isNotEmpty) {
    total = keyed.reduce((a, b) => a > b ? a : b);
  } else if (all.isNotEmpty) {
    total = all.reduce((a, b) => a > b ? a : b);
  }

  return ReceiptScan(
    total: total,
    merchant: _findMerchant(lines),
    date: _findDate(text, now ?? DateTime.now()),
    rawText: text,
  );
}

// ── OCR ──────────────────────────────────────────────────────────────────────

/// On-device text recognition (ML Kit). Nothing leaves the phone.
class ReceiptScanner {
  /// ML Kit runs on Android and iOS only.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<ReceiptScan> scanFile(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(path));
      return parseReceiptText(result.text);
    } finally {
      await recognizer.close();
    }
  }
}
