import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/core/constants/app_links.dart';
import 'package:paypact/core/navigation/auth_redirect.dart';
import 'package:paypact/core/utils/invite_code.dart';

void main() {
  group('generateInviteCode', () {
    test('is 8 unambiguous characters', () {
      final code = generateInviteCode();
      expect(code, matches(RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$')));
    });

    test('is deterministic for a seeded Random and varies otherwise', () {
      expect(generateInviteCode(Random(1)), generateInviteCode(Random(1)));
      final codes = {for (var i = 0; i < 200; i++) generateInviteCode()};
      expect(codes.length, 200);
    });
  });

  group('normalizeInviteCode', () {
    test('uppercases and trims valid codes', () {
      expect(normalizeInviteCode(' abcd2345 '), 'ABCD2345');
    });

    test('rejects malformed input', () {
      expect(normalizeInviteCode(null), isNull);
      expect(normalizeInviteCode(''), isNull);
      expect(normalizeInviteCode('abc'), isNull);
      expect(normalizeInviteCode('ABCD-2345'), isNull);
      expect(normalizeInviteCode('A' * 17), isNull);
    });
  });

  group('AppLinks', () {
    test('builds the shareable https link', () {
      expect(AppLinks.invite('ABCD2345'),
          'https://paypact-fec8e.web.app/invite/ABCD2345');
    });

    test('extracts the code from every link we hand out', () {
      String? code(String url) => AppLinks.inviteCodeFrom(Uri.parse(url));
      expect(code('https://paypact-fec8e.web.app/invite/abcd2345'), 'ABCD2345');
      expect(code('https://paypact-fec8e.web.app/join/ABCD2345'), 'ABCD2345');
      expect(code('/join/ABCD2345'), 'ABCD2345');
      expect(code('paypact://invite/ABCD2345'), 'ABCD2345');
    });

    test('ignores everything else', () {
      String? code(String url) => AppLinks.inviteCodeFrom(Uri.parse(url));
      expect(code('https://paypact-fec8e.web.app/'), isNull);
      expect(code('https://paypact-fec8e.web.app/invite/'), isNull);
      expect(code('https://paypact-fec8e.web.app/group/ABCD2345'), isNull);
      expect(code('paypact://settings/ABCD2345'), isNull);
      expect(code('paypact://invite'), isNull);
    });
  });

  group('routeForUnmatched', () {
    test('maps custom-scheme and bare-code links onto /join', () {
      expect(routeForUnmatched(Uri.parse('paypact://invite/ABCD2345')),
          '/join/ABCD2345');
      expect(routeForUnmatched(Uri.parse('/abcd2345')), '/join/ABCD2345');
    });

    test('sends everything else home instead of swallowing typos', () {
      expect(routeForUnmatched(Uri.parse('/nothing-here')), '/');
      expect(routeForUnmatched(Uri.parse('/typo')), '/');
      expect(routeForUnmatched(Uri.parse('/two/segments')), '/');
    });
  });
}
