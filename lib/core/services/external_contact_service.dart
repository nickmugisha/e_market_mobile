import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/whatsapp_link.dart';

class ExternalContactFailure implements Exception {
  const ExternalContactFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExternalContactService {
  const ExternalContactService();

  Future<void> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final digits = WhatsAppLink.normalizePhone(phone);

    if (digits.length < 8 || digits.length > 15) {
      throw const FormatException('Invalid WhatsApp phone number.');
    }

    final cleanMessage = message.trim();

    final uri = kIsWeb
        ? Uri.https('web.whatsapp.com', '/send', {
            'phone': digits,
            'text': cleanMessage,
          })
        : Uri(
            scheme: 'whatsapp',
            host: 'send',
            queryParameters: {'phone': digits, 'text': cleanMessage},
          );

    try {
      final opened = await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );

      if (!opened) {
        throw ExternalContactFailure(
          kIsWeb
              ? 'WhatsApp Web could not be opened.'
              : 'WhatsApp is not installed or could not be opened.',
        );
      }
    } on ExternalContactFailure {
      rethrow;
    } catch (_) {
      throw ExternalContactFailure(
        kIsWeb
            ? 'WhatsApp Web could not be opened.'
            : 'WhatsApp is not installed or could not be opened.',
      );
    }
  }
}
