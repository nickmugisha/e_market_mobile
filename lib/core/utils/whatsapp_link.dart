abstract final class WhatsAppLink {
  static String normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    // e-market is being demonstrated in Burundi. Accept a common local
    // 8-digit number and convert it to the international Burundi form.
    if (digits.length == 8) {
      digits = '257$digits';
    }

    return digits;
  }

  static bool isValidPhone(String input) {
    final digits = normalizePhone(input);
    return digits.length >= 8 && digits.length <= 15;
  }

  static Uri build({required String phone, required String message}) {
    final digits = normalizePhone(phone);
    if (digits.length < 8 || digits.length > 15) {
      throw const FormatException('Invalid WhatsApp phone number.');
    }

    return Uri.https('wa.me', '/$digits', {'text': message.trim()});
  }
}
