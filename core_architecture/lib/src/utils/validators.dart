// core/utils/validators.dart

/// Common validation utilities
class Validators {
  Validators._();

  // ==================== Email Validation ====================

  static String? email(String? value, {required String errorMessage}) {
    if (value == null || value.isEmpty) return errorMessage;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) return errorMessage;

    return null;
  }

  // ==================== Password Validation ====================

  static String? password(
    String? value, {
    int minLength = 6,
    required String errorMessage,
  }) {
    if (value == null || value.isEmpty) return errorMessage;
    if (value.length < minLength) return errorMessage;
    return null;
  }

  static String? confirmPassword(
    String? value,
    String? password, {
    required String errorMessage,
  }) {
    if (value == null || value.isEmpty) return errorMessage;
    if (value != password) return errorMessage;
    return null;
  }

  // ==================== Required Field Validation ====================

  static String? required(String? value, {required String errorMessage}) {
    if (value == null || value.isEmpty) return errorMessage;
    return null;
  }

  // ==================== Number Validation ====================

  static String? number(String? value, {required String errorMessage}) {
    if (value == null || value.isEmpty) return errorMessage;
    if (double.tryParse(value) == null) return errorMessage;
    return null;
  }

  static String? positiveNumber(String? value, {required String errorMessage}) {
    final error = number(value, errorMessage: errorMessage);
    if (error != null) return error;
    if (double.parse(value!) <= 0) return errorMessage;
    return null;
  }

  static String? amount(String? value, {required String errorMessage}) {
    if (value == null || value.isEmpty) return errorMessage;
    final parsed = double.tryParse(value);
    if (parsed == null) return errorMessage;
    if (parsed <= 0) return errorMessage;
    return null;
  }

  // ==================== Length Validation ====================

  static String? minLength(
    String? value,
    int min, {
    required String errorMessage,
  }) {
    if (value == null || value.isEmpty) return errorMessage;
    if (value.length < min) return errorMessage;
    return null;
  }

  static String? maxLength(
    String? value,
    int max, {
    required String errorMessage,
  }) {
    if (value == null || value.isEmpty) return null;
    if (value.length > max) return errorMessage;
    return null;
  }

  static String? lengthRange(
    String? value,
    int min,
    int max, {
    required String errorMessage,
  }) {
    if (value == null || value.isEmpty) return errorMessage;
    if (value.length < min || value.length > max) return errorMessage;
    return null;
  }

  // ==================== Phone Validation ====================

  static String? phone(String? value, {required String errorMessage}) {
    if (value == null || value.isEmpty) return errorMessage;
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned)) return errorMessage;
    return null;
  }

  // ==================== URL Validation ====================

  static String? url(String? value, {required String errorMessage}) {
    if (value == null || value.isEmpty) return errorMessage;

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) return errorMessage;
    return null;
  }

  // ==================== Date Validation ====================

  static String? date(String? value, {required String errorMessage}) {
    if (value == null || value.isEmpty) return errorMessage;
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return errorMessage;
    }
  }

  static String? futureDate(String? value, {required String errorMessage}) {
    final error = date(value, errorMessage: errorMessage);
    if (error != null) return error;
    if (DateTime.parse(value!).isBefore(DateTime.now())) return errorMessage;
    return null;
  }

  static String? pastDate(String? value, {required String errorMessage}) {
    final error = date(value, errorMessage: errorMessage);
    if (error != null) return error;
    if (DateTime.parse(value!).isAfter(DateTime.now())) return errorMessage;
    return null;
  }

  // ==================== Custom Validation ====================

  static String? custom(
    String? value,
    bool Function(String) validator,
    String errorMessage,
  ) {
    if (value == null || value.isEmpty) return errorMessage;
    if (!validator(value)) return errorMessage;
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
