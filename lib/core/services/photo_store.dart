import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

/// Photos live in Firestore documents (no Cloud Storage on the free plan).
///
/// A document holds one JPEG as a blob under `data` and has to stay below
/// Firestore's 1 MiB document limit, so every photo is re-encoded until it
/// fits [maxBytes]. A photo is addressed by a reference string
/// (`fsimg:<document path>#<version>`) that is stored wherever a URL used to
/// be (`photoUrl`, `coverUrl`, `receiptUrl`). The version changes on every
/// save, which doubles as the cache key.
class PhotoStore {
  PhotoStore(this._db);
  final FirebaseFirestore _db;

  static const scheme = 'fsimg:';
  static const maxBytes = 700 * 1024;

  /// Recently shown photos, keyed by reference (so a replaced photo is a miss).
  static final _cache = <String, Uint8List>{};
  static const _cacheLimit = 40;

  static bool isRef(String? s) => s != null && s.startsWith(scheme);

  Future<String> saveAvatar(String userId, Uint8List bytes) =>
      _save('users/$userId/photos/avatar', bytes);

  Future<String> saveGroupCover(String groupId, Uint8List bytes) =>
      _save('groups/$groupId/photos/cover', bytes);

  Future<String> saveReceipt(String groupId, Uint8List bytes) =>
      _save('groups/$groupId/photos/receipt_${const Uuid().v4()}', bytes);

  Future<String> _save(String path, Uint8List bytes) async {
    final fitted = await fit(bytes);
    await _db.doc(path).set({
      'data': Blob(fitted),
      'size': fitted.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final ref = '$scheme$path#${DateTime.now().millisecondsSinceEpoch}';
    _remember(ref, fitted);
    return ref;
  }

  /// The photo's bytes, or null if it no longer exists.
  Future<Uint8List?> load(String ref) async {
    final hit = _cache[ref];
    if (hit != null) return hit;
    final path = pathOf(ref);
    if (path == null) return null;
    final snap = await _db.doc(path).get();
    final blob = snap.data()?['data'];
    if (blob is! Blob) return null;
    final bytes = Uint8List.fromList(blob.bytes);
    _remember(ref, bytes);
    return bytes;
  }

  /// Best-effort delete of a photo document by its reference.
  Future<void> delete(String? ref) async {
    if (!isRef(ref)) return;
    final path = pathOf(ref!);
    if (path == null) return;
    _cache.remove(ref);
    try {
      await _db.doc(path).delete();
    } catch (_) {}
  }

  static String? pathOf(String ref) {
    if (!isRef(ref)) return null;
    final body = ref.substring(scheme.length);
    final hash = body.indexOf('#');
    final path = hash < 0 ? body : body.substring(0, hash);
    return path.isEmpty ? null : path;
  }

  static void _remember(String ref, Uint8List bytes) {
    _cache.remove(ref);
    _cache[ref] = bytes;
    while (_cache.length > _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Re-encodes [bytes] as a JPEG that fits [limit], shrinking as needed.
  static Future<Uint8List> fit(Uint8List bytes, {int limit = maxBytes}) async {
    if (bytes.length <= limit) return bytes;
    return compute(_shrink, _ShrinkJob(bytes, limit));
  }
}

class _ShrinkJob {
  const _ShrinkJob(this.bytes, this.limit);
  final Uint8List bytes;
  final int limit;
}

Uint8List _shrink(_ShrinkJob job) {
  var image = img.decodeImage(job.bytes);
  if (image == null) throw const FormatException('Not an image');
  var quality = 80;
  Uint8List out = job.bytes;
  for (var i = 0; i < 8; i++) {
    out = Uint8List.fromList(img.encodeJpg(image!, quality: quality));
    if (out.length <= job.limit) return out;
    // Smaller dimensions shrink fastest; trim quality too on later rounds.
    image = img.copyResize(image,
        width: (image.width * 0.8).round().clamp(64, image.width));
    if (i >= 2) quality = (quality - 8).clamp(40, 100);
  }
  return out;
}
