
import 'package:flutter/services.dart';

class NativeImagePicker {
  static const MethodChannel _channel = MethodChannel(
    'com.example.e_market/native_image_picker',
  );

  Future<Uint8List?> pickCompressedImage() async {
    final bytes = await _channel.invokeMethod<Uint8List>('pickImage');
    return bytes;
  }
}
