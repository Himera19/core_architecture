import 'package:core_architecture/core_architecture.dart';
import 'package:flutter_test/flutter_test.dart';

/// Labels are passed in by the caller, so the test picks trivial ones.
String relative(DateTime date) => DateHelper.getRelativeDate(
  date,
  todayLabel: 'today',
  yesterdayLabel: 'yesterday',
  tomorrowLabel: 'tomorrow',
  daysAgoSuffix: 'days ago',
  daysLaterSuffix: 'days later',
);

void main() {
  group('getRelativeDate counts calendar days, not elapsed hours', () {
    test('late last night is yesterday, however few hours ago it was', () {
      final DateTime now = DateTime.now();
      final DateTime lastMidnight = DateTime(now.year, now.month, now.day);

      // One minute before today started. Elapsed time can be as little as a
      // minute, which the old Duration.inDays reading called "today".
      expect(
        relative(lastMidnight.subtract(const Duration(minutes: 1))),
        'yesterday',
      );
    });

    test('earlier the same day is today, however many hours ago it was', () {
      final DateTime now = DateTime.now();
      final DateTime justAfterMidnight =
          DateTime(now.year, now.month, now.day, 0, 1);

      expect(relative(justAfterMidnight), 'today');
    });

    test('just after midnight tomorrow is tomorrow', () {
      final DateTime now = DateTime.now();
      final DateTime tomorrow =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      expect(relative(tomorrow.add(const Duration(minutes: 1))), 'tomorrow');
    });

    test('a few days either side counts whole calendar days', () {
      final DateTime now = DateTime.now();
      final DateTime midnight = DateTime(now.year, now.month, now.day);

      expect(relative(midnight.subtract(const Duration(days: 3))), '3 days ago');
      expect(relative(midnight.add(const Duration(days: 3))), '3 days later');
    });

    test('beyond a week falls back to the exact date', () {
      final DateTime old = DateTime(2024, 1, 15);
      expect(relative(old), DateHelper.formatDate(old));
    });
  });
}
