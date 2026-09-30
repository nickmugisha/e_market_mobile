import '../../auth/domain/user_profile.dart';
import '../../../core/utils/whatsapp_link.dart';

abstract final class ProfileValidator {
  static String? validateName(String value) {
    final cleaned = value.trim();
    if (cleaned.length < 2) {
      return 'Enter your name.';
    }
    if (cleaned.length > 80) {
      return 'Name is too long.';
    }
    return null;
  }

  static String? validatePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6 || digits.length > 15) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? validateWhatsApp({
    required UserRole role,
    required String value,
  }) {
    if (role == UserRole.client) {
      return value.trim().isEmpty
          ? null
          : 'Client profiles do not use a seller WhatsApp number.';
    }

    if (!WhatsAppLink.isValidPhone(value)) {
      return 'Enter a valid seller WhatsApp number.';
    }

    return null;
  }
}
