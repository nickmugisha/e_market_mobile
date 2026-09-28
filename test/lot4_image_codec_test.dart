import 'dart:typed_data';

import 'package:e_market/features/catalogue/utils/product_image_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product image codec round-trips bytes', () {
    final original = Uint8List.fromList([1, 2, 3, 4, 5, 250]);

    final encoded = ProductImageCodec.encode(original);
    final decoded = ProductImageCodec.decode(encoded);

    expect(encoded, startsWith('data:image;base64,'));
    expect(decoded, orderedEquals(original));
  });

  test('product image codec rejects invalid data', () {
    expect(ProductImageCodec.decode(''), isNull);
    expect(ProductImageCodec.decode('https://example.com/image.jpg'), isNull);
    expect(ProductImageCodec.decode('data:image;base64,%%%'), isNull);
  });

  test('Firestore image budget is bounded', () {
    final accepted = Uint8List(ProductImageCodec.maxRawBytes);
    final rejected = Uint8List(ProductImageCodec.maxRawBytes + 1);

    expect(ProductImageCodec.fitsFirestoreBudget(accepted), isTrue);
    expect(ProductImageCodec.fitsFirestoreBudget(rejected), isFalse);
  });
}
