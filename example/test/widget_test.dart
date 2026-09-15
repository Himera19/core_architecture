import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_architecture_demo/main.dart';
import 'package:core_architecture_demo/screens/domain_screen.dart';
import 'package:core_architecture_demo/screens/home_screen.dart';
import 'package:core_architecture_demo/screens/responsive_screen.dart';
import 'package:core_architecture_demo/screens/storage_screen.dart';
import 'package:core_architecture_demo/screens/theme_screen.dart';
import 'package:core_architecture_demo/screens/tokens_screen.dart';
import 'package:core_architecture_demo/screens/utils_screen.dart';
import 'package:core_architecture_demo/screens/widgets_screen.dart';
import 'package:core_architecture_demo/showcase/pulsing_dots.dart';

/// Stands in for the platform keychain, which no test host has.
class FakeStorage implements StorageService {
  final Map<String, String> _values = {};

  @override
  Future<void> write({required String key, required String value}) async =>
      _values[key] = value;

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> delete({required String key}) async => _values.remove(key);

  @override
  Future<void> clearAll() async => _values.clear();

  @override
  Future<bool> containsKey({required String key}) async =>
      _values.containsKey(key);
}

/// Pumps a fixed number of frames.
///
/// `pumpAndSettle` cannot be used here: several screens hold a continuous
/// animation — the loading buttons and the duration demo — so the frame queue
/// never empties and it times out. A second of frames covers every transition
/// these screens run, the 300ms bottom sheet included.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Mounts one showcase screen inside a real theme, the way the app does.
///
/// The window is made tall and wide enough that a page of sections fits
/// without the Row-based demos overflowing, which would fail the test for a
/// reason that has nothing to do with the package.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  FakeStorage? storage,
  Size size = const Size(1000, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage ?? FakeStorage()),
      ],
      child: MaterialApp(
        // Mirrors main.dart, loadingIndicatorBuilder included: a screen that
        // only looks right because the test theme differs from the app's is
        // not a screen that has been tested.
        theme: AppTheme.light(
          brandColor: brandColor,
          loadingIndicatorBuilder: loadingIndicator,
        ),
        darkTheme: AppTheme.dark(
          brandColor: brandColor,
          loadingIndicatorBuilder: loadingIndicator,
        ),
        home: screen,
      ),
    ),
  );
  await settle(tester);
}

void main() {
  // Each screen touches a different slice of the package, so rendering them
  // all is the broadest check that every export still builds and runs.
  group('every showcase screen renders', () {
    testWidgets('home lists one entry per area', (tester) async {
      await pumpScreen(tester, const HomeScreen());

      expect(find.text('core_architecture showcase'), findsOneWidget);
      for (final destination in HomeScreen.destinations) {
        expect(find.text(destination.title), findsOneWidget);
      }
    });

    testWidgets('theme', (tester) async {
      await pumpScreen(tester, const ThemeScreen());

      expect(find.text('Live theme mode'), findsOneWidget);
      expect(find.text('displaySm'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('tokens', (tester) async {
      await pumpScreen(tester, const TokensScreen());

      expect(find.text('Spacing ramp'), findsOneWidget);
      expect(find.text('tap me'), findsOneWidget);
    });

    testWidgets('widgets', (tester) async {
      await pumpScreen(tester, const WidgetsScreen());

      expect(find.byType(CustomButton), findsWidgets);
      expect(find.byType(CustomTextField), findsWidgets);
      expect(find.byType(CustomDropdown<String>), findsWidgets);
      expect(find.byType(CustomMultiSelectDropdown<String>), findsWidgets);
    });

    testWidgets('the duration demo actually widens when tapped', (
      tester,
    ) async {
      await pumpScreen(tester, const TokensScreen());

      final Finder box = find.ancestor(
        of: find.text('tap me'),
        matching: find.byType(AnimatedContainer),
      );

      // An off-screen widget hit-tests as a miss, so without this the tap
      // silently does nothing and the assertions below prove nothing.
      await tester.ensureVisible(find.text('tap me'));
      await settle(tester);

      final double collapsed = tester.getSize(box).width;

      await tester.tap(find.text('tap me'));
      await settle(tester);

      // Measured, not just "no exception": the earlier version of this test
      // only checked that tapping did not throw, so it stayed green while the
      // box never moved.
      final double expanded = tester.getSize(box).width;
      expect(expanded, greaterThan(collapsed));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('tap me'));
      await settle(tester);

      expect(tester.getSize(box).width, collapsed);
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive', (tester) async {
      await pumpScreen(tester, const ResponsiveScreen());

      expect(find.text('Where this window sits'), findsOneWidget);
      expect(find.text(PlatformInfo.platformName), findsOneWidget);
    });

    testWidgets('storage', (tester) async {
      await pumpScreen(tester, const StorageScreen());

      expect(find.text('Key-value storage, for real'), findsOneWidget);
      expect(find.text(StorageConstants.themeMode), findsOneWidget);
    });

    testWidgets('utils', (tester) async {
      await pumpScreen(tester, const UtilsScreen());

      expect(find.text('Relative dates, by calendar day'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('domain', (tester) async {
      await pumpScreen(tester, const DomainScreen());

      expect(find.text('1 · Climbing'), findsOneWidget);
      expect(find.text('2 · Pottery'), findsOneWidget);
    });
  });

  // A showcase is read on a phone too, and a RenderFlex overflow is an
  // exception, not a cosmetic warning — one already slipped through here.
  testWidgets('every screen survives a phone-width window', (tester) async {
    for (final screen in const <Widget>[
      HomeScreen(),
      ThemeScreen(),
      TokensScreen(),
      WidgetsScreen(),
      ResponsiveScreen(),
      StorageScreen(),
      UtilsScreen(),
      DomainScreen(),
    ]) {
      await pumpScreen(tester, screen, size: const Size(400, 6000));
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} overflowed at 400px',
      );
    }
  });

  group('the screens are wired to real behaviour, not mock text', () {
    testWidgets('toggling the theme moves the provider and persists', (
      tester,
    ) async {
      final FakeStorage storage = FakeStorage();
      await pumpScreen(tester, const ThemeScreen(), storage: storage);

      await tester.tap(find.text('toggleTheme()'));
      await settle(tester);

      expect(find.text('dark'), findsWidgets);
      expect(await storage.read(key: StorageConstants.themeMode), 'dark');
    });

    testWidgets('the form refuses an empty submit, then accepts a full one', (
      tester,
    ) async {
      await pumpScreen(tester, const WidgetsScreen());

      // ensureVisible, not scrollUntilVisible: the text fields on this page
      // are scrollables of their own, so the latter cannot tell which one to
      // drive.
      await tester.ensureVisible(find.text('Validate'));
      await settle(tester);
      await tester.tap(find.text('Validate'));
      await settle(tester);

      expect(find.text('Invalid email'), findsOneWidget);
      expect(find.text('City is required'), findsOneWidget);
      // The multi-select validator: before 4.0.0 it could not be satisfied.
      expect(find.text('Pick at least one tag'), findsOneWidget);
    });

    testWidgets('a multi-select choice satisfies its validator', (
      tester,
    ) async {
      await pumpScreen(tester, const WidgetsScreen());

      // ensureVisible, not scrollUntilVisible: the text fields on this page
      // are scrollables of their own, so the latter cannot tell which one to
      // drive.
      await tester.ensureVisible(find.text('Validate'));
      await settle(tester);
      await tester.tap(find.text('Validate'));
      await settle(tester);
      expect(find.text('Pick at least one tag'), findsOneWidget);

      // Opens the sheet by tapping the field's own label.
      await tester.tap(find.text('Required tags').first);
      await settle(tester);
      await tester.tap(find.text('riverpod').last);
      await settle(tester);
      await tester.tap(find.text('Done'));
      await settle(tester);

      await tester.tap(find.text('Validate'));
      await settle(tester);

      expect(find.text('Pick at least one tag'), findsNothing);
    });

    testWidgets('storage reads back what the screen wrote', (tester) async {
      final FakeStorage storage = FakeStorage();
      await pumpScreen(tester, const StorageScreen(), storage: storage);

      // ensureVisible, not scrollUntilVisible: the text fields on this page
      // are scrollables of their own, so the latter cannot tell which one to
      // drive.
      await tester.ensureVisible(find.text('write'));
      await settle(tester);
      await tester.tap(find.text('write'));
      await settle(tester);
      expect(await storage.read(key: 'demo_key'), 'demo value');

      await tester.tap(find.text('read'));
      await settle(tester);
      expect(find.text('read → demo value'), findsOneWidget);

      await tester.tap(find.text('delete'));
      await settle(tester);
      expect(await storage.read(key: 'demo_key'), isNull);
    });

    testWidgets('the CRUD fake inserts, counts and reports a missing row', (
      tester,
    ) async {
      await pumpScreen(tester, const DomainScreen());

      await tester.tap(find.text('insert'));
      await settle(tester);
      expect(find.text('3 · Hobby 3'), findsOneWidget);

      await tester.tap(find.text('count'));
      await settle(tester);
      expect(find.text('count → 3'), findsOneWidget);

      await tester.tap(find.text('getById("nope")'));
      await settle(tester);
      expect(
        find.textContaining('DatabaseException: No row with id nope'),
        findsOneWidget,
      );
    });

    testWidgets('the size tokens open a dialog built from them', (
      tester,
    ) async {
      await pumpScreen(tester, const TokensScreen());

      await tester.ensureVisible(
        find.text('Open a dialog sized by the tokens'),
      );
      await settle(tester);
      await tester.tap(find.text('Open a dialog sized by the tokens'));
      await settle(tester);

      expect(find.text('Sized by tokens'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The action really is dialogButtonWidth wide, not just labelled so.
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('Close'),
                matching: find.byType(SizedBox),
              ).first,
            )
            .width,
        AppSizes.dialogButtonWidth,
      );

      await tester.tap(find.text('Close'));
      await settle(tester);
      expect(find.text('Sized by tokens'), findsNothing);
    });

    testWidgets('the app\'s own spinner reaches every button through the theme', (
      tester,
    ) async {
      await pumpScreen(tester, const WidgetsScreen());

      // Four loading buttons, none of which asks for PulsingDots: they get it
      // from AppTheme(loadingIndicatorBuilder: ...) in main.dart.
      expect(find.byType(PulsingDots), findsNWidgets(ButtonType.values.length));

      // And the one button that overrides it keeps Material's spinner.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a loading button stops answering taps', (tester) async {
      await pumpScreen(tester, const WidgetsScreen());

      await tester.ensureVisible(find.text('run for 2s'));
      await settle(tester);
      await tester.tap(find.text('run for 2s'));
      await tester.pump();

      // It is loading now: the label is gone and the button is disabled, so a
      // second tap cannot start the work again.
      expect(find.text('run for 2s'), findsNothing);
      final Finder button = find.ancestor(
        of: find.byType(PulsingDots).first,
        matching: find.byType(ElevatedButton),
      );
      expect(tester.widget<ElevatedButton>(button).enabled, isFalse);

      await settle(tester, frames: 25);
      expect(find.text('run for 2s'), findsOneWidget);
    });

    testWidgets('the month strip is built from DateHelper', (tester) async {
      await pumpScreen(tester, const UtilsScreen());

      final DateTime now = DateTime.now();

      // One cell per day the helper reports for this month.
      expect(
        find.text('${DateHelper.getDaysInMonth(now).length}'),
        findsWidgets,
      );
      // The week header is getDayName, not a hardcoded list.
      expect(
        find.text(DateHelper.getDayName(now.weekday).substring(0, 3)),
        findsWidgets,
      );
      expect(
        find.textContaining(DateHelper.getMonthName(now.month)),
        findsWidgets,
      );
    });

    testWidgets('the responsive layer follows the window width', (
      tester,
    ) async {
      // Phone width: the size has to go through pumpScreen, which sets the
      // window itself.
      await pumpScreen(
        tester,
        const ResponsiveScreen(),
        size: const Size(400, 1400),
      );

      expect(find.text('compact'), findsWidgets);
      expect(find.text('compact builder — one column'), findsOneWidget);

      // Widening the same window has to move every readout with it.
      tester.view.physicalSize = const Size(1400, 1400);
      await settle(tester);

      expect(find.text('large'), findsWidgets);
      expect(find.text('large builder — four columns'), findsOneWidget);
      expect(find.text('compact builder — one column'), findsNothing);
    });
  });
}
