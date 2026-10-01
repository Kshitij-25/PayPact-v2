import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Picks a photo and returns JPEG bytes sized for upload, or null if cancelled.
class PhotoPicker {
  PhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  /// The camera isn't available on desktop/web browsers without a webcam
  /// prompt, so only the gallery/file chooser is offered there.
  static bool get cameraSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<Uint8List?> pickBytes(PhotoSource source,
      {double maxSide = 1600, int quality = 80}) async {
    final file = await pick(source, maxSide: maxSide, quality: quality);
    return file?.readAsBytes();
  }

  Future<XFile?> pick(PhotoSource source,
          {double maxSide = 1600, int quality = 80}) =>
      _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
      );
}
