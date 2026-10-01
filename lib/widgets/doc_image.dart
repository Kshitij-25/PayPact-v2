import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/services/photo_store.dart';

/// Shows a photo from either an `https` URL (e.g. a Google profile picture) or
/// a Firestore photo reference (see [PhotoStore]).
class DocImage extends StatefulWidget {
  const DocImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.error,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Shown while loading; defaults to nothing.
  final Widget? placeholder;

  /// Shown if the photo can't be loaded; defaults to [placeholder].
  final Widget? error;

  @override
  State<DocImage> createState() => _DocImageState();
}

class _DocImageState extends State<DocImage> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(DocImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _start();
  }

  void _start() {
    _future = PhotoStore.isRef(widget.url)
        ? locator<PhotoStore>().load(widget.url).catchError((_) => null)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final blank = widget.placeholder ?? const SizedBox.shrink();
    if (!PhotoStore.isRef(widget.url)) {
      return Image.network(
        widget.url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.error ?? blank,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : blank,
      );
    }
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return blank;
        final bytes = snap.data;
        if (bytes == null) return widget.error ?? blank;
        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => widget.error ?? blank,
        );
      },
    );
  }
}
