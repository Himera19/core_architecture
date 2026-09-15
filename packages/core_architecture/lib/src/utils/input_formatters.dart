import 'package:flutter/services.dart';

/// Formatter for phone numbers
/// Format: (XXX) XXX XX XX
class TurkishPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract digits only
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Maximum 10 digits (5XX XXX XX XX)
    if (digitsOnly.length > 10) {
      return oldValue;
    }

    // Format
    String formatted = '';
    if (digitsOnly.isNotEmpty) {
      // First 3 digits: (5XX)
      formatted =
          '(${digitsOnly.substring(0, digitsOnly.length > 3 ? 3 : digitsOnly.length)}';

      if (digitsOnly.length >= 3) {
        formatted += ') ';

        // Next 3 digits: XXX
        formatted += digitsOnly.substring(
          3,
          digitsOnly.length > 6 ? 6 : digitsOnly.length,
        );

        if (digitsOnly.length >= 6) {
          formatted += ' ';

          // Next 2 digits: XX
          formatted += digitsOnly.substring(
            6,
            digitsOnly.length > 8 ? 8 : digitsOnly.length,
          );

          if (digitsOnly.length >= 8) {
            formatted += ' ';

            // Last 2 digits: XX
            formatted += digitsOnly.substring(8);
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
