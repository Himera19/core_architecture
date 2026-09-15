import 'package:core_architecture/core_architecture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  // Any locale other than en needs its symbols loaded first; an app does this
  // once in main().
  setUpAll(initializeDateFormatting);

  tearDown(() => Intl.defaultLocale = null);

  // The names used to be two const Turkish lists, so a package that took every
  // other label as a parameter still decided the language of these.
  group('day and month names follow the locale', () {
    test('English', () {
      expect(DateHelper.getDayName(1, locale: 'en_US'), 'Monday');
      expect(DateHelper.getDayName(7, locale: 'en_US'), 'Sunday');
      expect(DateHelper.getMonthName(1, locale: 'en_US'), 'January');
      expect(DateHelper.getMonthName(12, locale: 'en_US'), 'December');
    });

    test('Turkish', () {
      expect(DateHelper.getDayName(1, locale: 'tr'), 'Pazartesi');
      expect(DateHelper.getDayName(7, locale: 'tr'), 'Pazar');
      expect(DateHelper.getMonthName(1, locale: 'tr'), 'Ocak');
      expect(DateHelper.getMonthName(12, locale: 'tr'), 'Aralık');
    });

    test('a locale set once in main covers every call', () {
      Intl.defaultLocale = 'tr';

      expect(DateHelper.getDayName(3), 'Çarşamba');
      expect(DateHelper.getMonthName(5), 'Mayıs');
    });

    test('the full lists are built from the same source', () {
      expect(DateHelper.dayNames(locale: 'en_US').first, 'Monday');
      expect(DateHelper.dayNames(locale: 'en_US').length, 7);
      expect(DateHelper.monthNames(locale: 'tr').first, 'Ocak');
      expect(DateHelper.monthNames(locale: 'tr').length, 12);
    });

    test('an index outside the range is empty, not a crash', () {
      expect(DateHelper.getDayName(0), '');
      expect(DateHelper.getDayName(8), '');
      expect(DateHelper.getMonthName(0), '');
      expect(DateHelper.getMonthName(13), '');
    });

    test('weekday numbers line up with DateTime.weekday', () {
      // 2024-01-01 was a Monday.
      final DateTime monday = DateTime(2024, 4, 8);

      expect(
        DateHelper.getDayName(monday.weekday, locale: 'en_US'),
        'Monday',
      );
      expect(
        DateHelper.getDayName(
          monday.add(const Duration(days: 6)).weekday,
          locale: 'en_US',
        ),
        'Sunday',
      );
    });
  });

  group('patterns can be overridden', () {
    final DateTime moment = DateTime(2024, 3, 9, 14, 5);

    test('the defaults are unchanged', () {
      expect(DateHelper.formatDate(moment), '09.03.2024');
      expect(DateHelper.formatTime(moment), '14:05');
      expect(DateHelper.formatDateTime(moment), '09.03.2024 14:05');
    });

    test('a caller can ask for its own', () {
      expect(
        DateHelper.formatDate(moment, pattern: 'yyyy-MM-dd'),
        '2024-03-09',
      );
      expect(
        DateHelper.formatDate(moment, pattern: 'd MMMM yyyy', locale: 'tr'),
        '9 Mart 2024',
      );
    });
  });
}
