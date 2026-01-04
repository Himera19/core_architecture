import 'package:intl/intl.dart';

class CurrencyHelper {
  CurrencyHelper._();

  static NumberFormat formatTurkishLira = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: 'TL',
    decimalDigits: 2,
  );

  /// Formats a double amount to Turkish currency format with comma as decimal separator
  /// Example: 50.50 -> "50,50"
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
}