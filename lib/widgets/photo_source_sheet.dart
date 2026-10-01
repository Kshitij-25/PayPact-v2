import 'package:flutter/material.dart';
import 'package:paypact/core/services/photo_picker.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';

/// Asks "camera or library?" where a camera exists; otherwise goes straight to
/// the file chooser. Returns null if dismissed.
Future<PhotoSource?> choosePhotoSource(BuildContext context,
    {bool allowRemove = false, VoidCallback? onRemove}) async {
  if (!PhotoPicker.cameraSupported && !allowRemove) {
    return PhotoSource.gallery;
  }
  final pt = context.pt;
  return showModalBottomSheet<PhotoSource>(
    context: context,
    backgroundColor: pt.surface,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (PhotoPicker.cameraSupported)
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, PhotoSource.camera),
          ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Choose from library'),
          onTap: () => Navigator.pop(ctx, PhotoSource.gallery),
        ),
        if (allowRemove)
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: pt.negative),
            title: Text('Remove photo', style: TextStyle(color: pt.negative)),
            onTap: () {
              Navigator.pop(ctx);
              onRemove?.call();
            },
          ),
      ]),
    ),
  );
}
