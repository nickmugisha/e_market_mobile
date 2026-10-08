import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class NativeImagePicker {
  NativeImagePicker({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int _maxBytes = 450 * 1024;
  static const int _maxDimension = 900;

  Future<Uint8List?> pickCompressedImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      return null;
    }

    final originalBytes = await pickedFile.readAsBytes();

    if (originalBytes.isEmpty) {
      throw StateError('The selected image is empty.');
    }

    final decoded = img.decodeImage(originalBytes);

    if (decoded == null) {
      throw StateError('Unsupported image format.');
    }

    final oriented = img.bakeOrientation(decoded);

    final dimensions = <int>[
      _maxDimension,
      760,
      640,
      520,
      420,
    ];

    final qualities = <int>[
      84,
      74,
      64,
      54,
      44,
      34,
    ];

    for (final maxSize in dimensions) {
      final resized = _resizeToFit(
        oriented,
        maxSize,
      );

      for (final quality in qualities) {
        final encoded = Uint8List.fromList(
          img.encodeJpg(
            resized,
            quality: quality,
          ),
        );

        if (encoded.lengthInBytes <= _maxBytes) {
          return encoded;
        }
      }
    }

    throw StateError(
      'The selected image could not be compressed enough.',
    );
  }

  img.Image _resizeToFit(
    img.Image source,
    int maxSize,
  ) {
    if (source.width <= maxSize &&
        source.height <= maxSize) {
      return source;
    }

    if (source.width >= source.height) {
      return img.copyResize(
        source,
        width: maxSize,
        interpolation: img.Interpolation.average,
      );
    }

    return img.copyResize(
      source,
      height: maxSize,
      interpolation: img.Interpolation.average,
    );
  }
}
