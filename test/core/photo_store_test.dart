import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paypact/core/services/photo_store.dart';
import 'package:paypact/features/auth/data/user_directory.dart';

void main() {
  test('references round-trip to their document path', () {
    const ref = 'fsimg:groups/g1/photos/cover#1727780000000';
    expect(PhotoStore.isRef(ref), isTrue);
    expect(PhotoStore.pathOf(ref), 'groups/g1/photos/cover');
    expect(PhotoStore.isRef('https://lh3.googleusercontent.com/a.jpg'), isFalse);
    expect(PhotoStore.isRef(null), isFalse);
    expect(PhotoStore.pathOf('https://x/y.jpg'), isNull);
  });

  test('small photos are left alone', () async {
    final bytes = Uint8List.fromList(List.filled(1000, 7));
    expect(await PhotoStore.fit(bytes), same(bytes));
  });

  test('big photos are re-encoded below the limit', () async {
    // Noise doesn't compress, so this is a worst-case photo.
    final rng = Random(1);
    final image = img.Image(width: 1600, height: 1600);
    for (final p in image) {
      p
        ..r = rng.nextInt(256)
        ..g = rng.nextInt(256)
        ..b = rng.nextInt(256);
    }
    final big = Uint8List.fromList(img.encodeJpg(image, quality: 95));
    expect(big.length, greaterThan(PhotoStore.maxBytes));

    final fitted = await PhotoStore.fit(big);
    expect(fitted.length, lessThanOrEqualTo(PhotoStore.maxBytes));
    expect(img.decodeJpg(fitted), isNotNull);
  });

  test('something that is not an image is rejected', () async {
    final junk = Uint8List.fromList(List.filled(PhotoStore.maxBytes + 10, 1));
    expect(PhotoStore.fit(junk), throwsA(isA<FormatException>()));
  });

  group('people directory', () {
    test('e-mail lookups are case/space-insensitive hashes, never the address', () {
      final a = UserDirectory.emailHash(' Kshitij@Gmail.com ');
      expect(a, UserDirectory.emailHash('kshitij@gmail.com'));
      expect(a, isNot(contains('kshitij')));
      expect(a, hasLength(64));
    });

    test('masking keeps the domain and hides the name', () {
      expect(UserDirectory.maskEmail('kshitij@gmail.com'), 'k••••@gmail.com');
      expect(UserDirectory.maskEmail('ab@x.io'), 'a•@x.io');
      expect(UserDirectory.maskEmail('nonsense'), '');
    });

    test('entries carry a lower-cased name for prefix search', () {
      final e = UserDirectory.entry(name: ' Asha Rao ', email: 'a@x.com');
      expect(e['nameLower'], 'asha rao');
      expect(e.containsKey('email'), isFalse);
    });
  });
}
