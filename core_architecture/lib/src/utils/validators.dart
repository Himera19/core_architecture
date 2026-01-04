// core/utils/validators.dart

/// Common validation utilities
class Validators {
  Validators._();

  // ==================== Email Validation ====================

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mail adresi gerekli';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir mail adresi girin';
    }

    return null;
  }

  // ==================== Password Validation ====================

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < minLength) {
      return 'Şifre en az $minLength karakter olmalı';
    }

    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Şifreyi doğrulayın';
    }

    if (value != password) {
      return 'Şifreler uyuşmuyor';
    }

    return null;
  }

  // ==================== Required Field Validation ====================

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }

    return null;
  }

  // ==================== Number Validation ====================

  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'Sayı gerekli';
    }

    if (double.tryParse(value) == null) {
      return 'Geçerli bir sayı girin';
    }

    return null;
  }

  static String? positiveNumber(String? value) {
    final numberError = number(value);
    if (numberError != null) return numberError;

    final numValue = double.parse(value!);
    if (numValue <= 0) {
      return 'Sayı 0\'dan büyük olmalı';
    }

    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tutar gerekli';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Geçerli bir tutar girin';
    }

    if (amount <= 0) {
      return 'Tutar 0\'dan büyük olmalı';
    }

    return null;
  }

  // ==================== Length Validation ====================

  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }

    if (value.length < min) {
      return '${fieldName ?? 'Bu alan'} en az $min karakter olmalı';
    }

    return null;
  }

  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length > max) {
      return '${fieldName ?? 'Bu alan'} en fazla $max karakter olabilir';
    }

    return null;
  }

  static String? lengthRange(
      String? value,
      int min,
      int max, {
        String? fieldName,
      }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }

    if (value.length < min || value.length > max) {
      return '${fieldName ?? 'Bu alan'} $min ile $max karakter arasında olmalı';
    }

    return null;
  }

  // ==================== Phone Validation ====================

  /// Türk telefon numarası validasyonu
  /// Format: (5XX) XXX XX XX
  static String? turkishPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }

    // Sadece rakamları al
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // 10 haneli olmalı
    if (digitsOnly.length != 10) {
      return 'Telefon numarası 10 haneli olmalı';
    }

    // 5 ile başlamalı
    if (!digitsOnly.startsWith('5')) {
      return 'Telefon numarası 5 ile başlamalı';
    }

    return null;
  }

  /// TC Kimlik numarası validasyonu
  /// 11 haneli, 0 ile başlamayan
  static String? tcNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Opsiyonel alan
    }

    // Sadece rakamları al
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // 11 haneli olmalı
    if (digitsOnly.length != 11) {
      return 'TC Kimlik numarası 11 haneli olmalı';
    }

    // 0 ile başlamamalı
    if (digitsOnly.startsWith('0')) {
      return 'TC Kimlik numarası 0 ile başlayamaz';
    }

    // TC Kimlik numarası algoritması kontrolü
    if (!_isValidTcNumber(digitsOnly)) {
      return 'Geçersiz TC Kimlik numarası';
    }

    return null;
  }

  /// TC Kimlik numarası algoritma kontrolü
  static bool _isValidTcNumber(String tc) {
    if (tc.length != 11) return false;

    final digits = tc.split('').map((e) => int.parse(e)).toList();

    // İlk 10 hanenin toplamının birler basamağı 11. haneye eşit olmalı
    final sum = digits.sublist(0, 10).reduce((a, b) => a + b);
    if (sum % 10 != digits[10]) return false;

    // 1, 3, 5, 7, 9. hanelerin toplamının 7 katından
    // 2, 4, 6, 8. hanelerin toplamını çıkarınca
    // elde edilen sonucun birler basamağı 10. haneye eşit olmalı
    final oddSum = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
    final evenSum = digits[1] + digits[3] + digits[5] + digits[7];
    if ((oddSum * 7 - evenSum) % 10 != digits[9]) return false;

    return true;
  }

  /// Genel telefon validasyonu (eski versiyon - geriye dönük uyumluluk için)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned)) {
      return 'Geçerli bir telefon numarası girin';
    }

    return null;
  }

  // ==================== URL Validation ====================

  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL gerekli';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Geçerli bir URL girin';
    }

    return null;
  }

  // ==================== Date Validation ====================

  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tarih gerekli';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Geçerli bir tarih girin';
    }
  }

  static String? futureDate(String? value) {
    final dateError = date(value);
    if (dateError != null) return dateError;

    final parsedDate = DateTime.parse(value!);
    if (parsedDate.isBefore(DateTime.now())) {
      return 'Tarih gelecekte olmalı';
    }

    return null;
  }

  static String? pastDate(String? value) {
    final dateError = date(value);
    if (dateError != null) return dateError;

    final parsedDate = DateTime.parse(value!);
    if (parsedDate.isAfter(DateTime.now())) {
      return 'Tarih geçmişte olmalı';
    }

    return null;
  }

  // ==================== Custom Validation ====================

  static String? custom(
      String? value,
      bool Function(String) validator,
      String errorMessage,
      ) {
    if (value == null || value.isEmpty) {
      return errorMessage;
    }

    if (!validator(value)) {
      return errorMessage;
    }

    return null;
  }

  // ==================== Compose Multiple Validators ====================

  static String? Function(String?) compose(
      List<String? Function(String?)> validators,
      ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
