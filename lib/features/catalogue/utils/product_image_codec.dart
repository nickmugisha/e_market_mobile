import 'dart:convert';
import 'dart:typed_data';

abstract final class ProductImageCodec {
  static const int maxRawBytes = 450 * 1024;

  static bool fitsFirestoreBudget(Uint8List bytes) =>
      bytes.lengthInBytes <= maxRawBytes;

  static String encode(Uint8List bytes) {
    return 'data:image;base64,${base64Encode(bytes)}';
  }

  static Uint8List? decode(String value) {
    if (!value.startsWith('data:image')) return null;

    final commaIndex = value.indexOf(',');
    if (commaIndex < 0 || commaIndex == value.length - 1) return null;

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } on FormatException {
      return null;
    }
  }
}
