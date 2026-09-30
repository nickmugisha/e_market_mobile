import 'package:e_market/core/utils/whatsapp_link.dart';
import 'package:e_market/features/auth/domain/user_profile.dart';
import 'package:e_market/features/profile/domain/profile_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Burundi local WhatsApp number is normalized', () {
    expect(
      WhatsAppLink.normalizePhone('79 12 34 56'),
      '25779123456',
    );
  });

  test('international WhatsApp number keeps its country code', () {
    expect(
      WhatsAppLink.normalizePhone('+257 79 12 34 56'),
      '25779123456',
    );
  });

  test('00 international prefix is normalized', () {
    expect(
      WhatsAppLink.normalizePhone('00257 79 12 34 56'),
      '25779123456',
    );
  });

  test('WhatsApp link contains the normalized number and message', () {
    final uri = WhatsAppLink.build(
      phone: '+257 79 12 34 56',
      message: 'Hello seller',
    );

    expect(uri.host, 'wa.me');
    expect(uri.path, '/25779123456');
    expect(uri.queryParameters['text'], 'Hello seller');
  });

  test('seller profile requires a valid WhatsApp number', () {
    expect(
      ProfileValidator.validateWhatsApp(
        role: UserRole.seller,
        value: '',
      ),
      isNotNull,
    );

    expect(
      ProfileValidator.validateWhatsApp(
        role: UserRole.seller,
        value: '+257 79 12 34 56',
      ),
      isNull,
    );
  });

  test('client profile must not keep seller WhatsApp data', () {
    expect(
      ProfileValidator.validateWhatsApp(
        role: UserRole.client,
        value: '',
      ),
      isNull,
    );

    expect(
      ProfileValidator.validateWhatsApp(
        role: UserRole.client,
        value: '+25779123456',
      ),
      isNotNull,
    );
  });

  test('profile name and phone validation reject empty values', () {
    expect(ProfileValidator.validateName(''), isNotNull);
    expect(ProfileValidator.validatePhone('12'), isNotNull);
    expect(ProfileValidator.validateName('Collin'), isNull);
    expect(ProfileValidator.validatePhone('79123456'), isNull);
  });
}
