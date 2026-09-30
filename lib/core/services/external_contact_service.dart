import 'package:flutter/services.dart';

import '../utils/whatsapp_link.dart';

class ExternalContactFailure implements Exception {
  const ExternalContactFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExternalContactService {
  const ExternalContactService();

  static const _channel = MethodChannel(
    'com.example.e_market/external_contact',
  );

  Future<void> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final uri = WhatsAppLink.build(
      phone: phone,
      message: message,
    );

    try {
      final opened = await _channel.invokeMethod<bool>(
        'openUrl',
        {'url': uri.toString()},
      );

      if (opened != true) {
        throw const ExternalContactFailure(
          'No app or browser could open WhatsApp.',
        );
      }
    } on PlatformException catch (error) {
      throw ExternalContactFailure(
        error.message ?? 'Could not open WhatsApp.',
      );
    }
  }
}
