import 'dart:math';

// No 0/O/1/I so a code read aloud or typed from a screenshot isn't ambiguous.
const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// A random, unguessable group invite code (8 chars ≈ 40 bits).
String generateInviteCode([Random? random]) {
  final rng = random ?? Random.secure();
  return String.fromCharCodes(
    List.generate(
        8, (_) => _alphabet.codeUnitAt(rng.nextInt(_alphabet.length))),
  );
}

final _codePattern = RegExp(r'^[A-Z0-9]{6,16}$');

/// Normalises user/deep-link input to a canonical code, or null if malformed.
String? normalizeInviteCode(String? raw) {
  final code = raw?.trim().toUpperCase();
  if (code == null || !_codePattern.hasMatch(code)) return null;
  return code;
}
