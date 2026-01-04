import 'package:flutter/services.dart';

/// Türk telefon numarası için formatter
/// Format: (5XX) XXX XX XX
class TurkishPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Sadece rakamları al
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Maksimum 10 rakam (5XX XXX XX XX)
    if (digitsOnly.length > 10) {
      return oldValue;
    }



    // Formatla
    String formatted = '';
    if (digitsOnly.isNotEmpty) {
      // İlk 3 rakam: (5XX)
      formatted = '(${digitsOnly.substring(0, digitsOnly.length > 3 ? 3 : digitsOnly.length)}';
      
      if (digitsOnly.length >= 3) {
        formatted += ') ';
        
        // Sonraki 3 rakam: XXX
        formatted += digitsOnly.substring(3, digitsOnly.length > 6 ? 6 : digitsOnly.length);
        
        if (digitsOnly.length >= 6) {
          formatted += ' ';
          
          // Sonraki 2 rakam: XX
          formatted += digitsOnly.substring(6, digitsOnly.length > 8 ? 8 : digitsOnly.length);
          
          if (digitsOnly.length >= 8) {
            formatted += ' ';
            
            // Son 2 rakam: XX
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

/// TC Kimlik numarası için formatter
/// Format: 11 haneli rakam
class TcNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Sadece rakamları al
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Maksimum 11 rakam
    if (digitsOnly.length > 11) {
      return oldValue;
    }

    // İlk rakam 0 olamaz
    if (digitsOnly.isNotEmpty && digitsOnly[0] == '0') {
      return oldValue;
    }

    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }
}
