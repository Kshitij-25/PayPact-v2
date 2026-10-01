import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Uploads user photos. Paths line up with storage.rules: avatars are public
/// to signed-in users; anything under groups/{id}/ is members-only.
class StorageService {
  StorageService(this._storage);
  final FirebaseStorage _storage;

  static final _jpeg = SettableMetadata(contentType: 'image/jpeg');

  Future<String> _put(String path, Uint8List bytes) async {
    final ref = _storage.ref(path);
    await ref.putData(bytes, _jpeg);
    return ref.getDownloadURL();
  }

  Future<String> uploadReceipt(String groupId, Uint8List bytes) =>
      _put('groups/$groupId/receipts/${const Uuid().v4()}.jpg', bytes);

  Future<String> uploadGroupCover(String groupId, Uint8List bytes) async {
    // A fresh name each time so a replaced cover isn't served from a stale cache.
    return _put('groups/$groupId/covers/${const Uuid().v4()}.jpg', bytes);
  }

  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    // The rules pin avatars to `{uid}.jpg`; bust the cache with a query param.
    final url = await _put('avatars/$userId.jpg', bytes);
    final bust = DateTime.now().millisecondsSinceEpoch;
    return url.contains('?') ? '$url&v=$bust' : '$url?v=$bust';
  }

  /// Best-effort delete of a previously uploaded file by its download URL.
  Future<void> deleteByUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
