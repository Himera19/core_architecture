import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mounts [child] in a box narrower than its natural width, which is where a
/// full-width button meets a label it cannot fit.
Future<void> pumpInBox(
  WidgetTester tester,
  Widget child, {
  double width = 200,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('a label wider than the button is trimmed, not overflowed', () {
    // CustomButton is width: double.infinity, so the label has exactly the
    // button's width to work with. In the icon variant it sat in a
    // mainAxisSize.min Row with no Flexible, so it pushed past the edge and
    // the framework reported a RenderFlex overflow.
    testWidgets('with an icon', (tester) async {
      await pumpInBox(
        tester,
        CustomButton(
          text: 'A label far too long to fit in this button',
          icon: Icons.calendar_today,
          onPressed: () {},
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('without an icon', (tester) async {
      await pumpInBox(
        tester,
        CustomButton(
          text: 'A label far too long to fit in this button',
          onPressed: () {},
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('at every size', (tester) async {
      for (final size in ButtonSize.values) {
        await pumpInBox(
          tester,
          CustomButton(
            text: 'A label far too long to fit in this button',
            icon: Icons.star,
            size: size,
            onPressed: () {},
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason: '${size.name} overflowed',
        );
      }
    });

    testWidgets('the label is ellipsized on one line', (tester) async {
      await pumpInBox(
        tester,
        CustomButton(
          text: 'A label far too long to fit in this button',
          icon: Icons.star,
          onPressed: () {},
        ),
      );

      final Text label = tester.widget<Text>(
        find.text('A label far too long to fit in this button'),
      );

      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
    });
  });

  testWidgets('a label that fits is untouched', (tester) async {
    await pumpInBox(tester, CustomButton(text: 'OK', onPressed: () {}));

    expect(tester.takeException(), isNull);
    expect(find.text('OK'), findsOneWidget);
  });

  group('the loading indicator', () {
    // The package ships no animation library; the default comes from Material
    // and anything fancier is the app's own dependency, passed in.
    testWidgets('defaults to a Material spinner, replacing the label', (
      tester,
    ) async {
      await pumpInBox(
        tester,
        CustomButton(text: 'Save', isLoading: true, onPressed: () {}),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('is tinted to the button it sits in, not always onPrimary', (
      tester,
    ) async {
      final ColorScheme scheme = AppTheme.light().colorScheme;

      await pumpInBox(
        tester,
        CustomButton(
          text: 'Save',
          type: ButtonType.outlined,
          isLoading: true,
          onPressed: () {},
        ),
      );

      // An outlined button is transparent, so an onPrimary spinner would be
      // white on white — it takes the foreground instead.
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        scheme.primary,
      );
    });

    testWidgets('gives way to one the app supplies', (tester) async {
      await pumpInBox(
        tester,
        CustomButton(
          text: 'Save',
          isLoading: true,
          loadingIndicator: const Text('…'),
          onPressed: () {},
        ),
      );

      expect(find.text('…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('is absent when the button is idle', (tester) async {
      await pumpInBox(tester, CustomButton(text: 'Save', onPressed: () {}));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('an app-wide indicator on the theme', () {
    ThemeData themeWithBuilder() => AppTheme.light(
      loadingIndicatorBuilder: (context, color) =>
          Text('app spinner', style: TextStyle(color: color)),
    );

    testWidgets('serves every button without touching the call sites', (
      tester,
    ) async {
      await pumpInBox(
        tester,
        CustomButton(text: 'Save', isLoading: true, onPressed: () {}),
        theme: themeWithBuilder(),
      );

      expect(find.text('app spinner'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('is handed the foreground of the button asking', (
      tester,
    ) async {
      final ColorScheme scheme = AppTheme.light().colorScheme;

      await pumpInBox(
        tester,
        CustomButton(
          text: 'Save',
          type: ButtonType.outlined,
          isLoading: true,
          onPressed: () {},
        ),
        theme: themeWithBuilder(),
      );

      // One builder covers every ButtonType because the colour is passed in.
      expect(
        tester.widget<Text>(find.text('app spinner')).style?.color,
        scheme.primary,
      );
    });

    testWidgets('yields to a button that brings its own', (tester) async {
      await pumpInBox(
        tester,
        CustomButton(
          text: 'Save',
          isLoading: true,
          loadingIndicator: const Text('this button only'),
          onPressed: () {},
        ),
        theme: themeWithBuilder(),
      );

      expect(find.text('this button only'), findsOneWidget);
      expect(find.text('app spinner'), findsNothing);
    });

    testWidgets('the extension is installed even when none was given', (
      tester,
    ) async {
      await pumpInBox(tester, CustomButton(text: 'Save', onPressed: () {}));

      final BuildContext context = tester.element(find.byType(CustomButton));
      final CoreComponentsTheme? extension = CoreComponentsTheme.maybeOf(
        context,
      );

      expect(extension, isNotNull);
      expect(extension!.loadingIndicatorBuilder, isNull);
    });
  });

  group('a loading button does not accept input', () {
    testWidgets('its callback is not reachable', (tester) async {
      int taps = 0;

      await pumpInBox(
        tester,
        CustomButton(text: 'Save', isLoading: true, onPressed: () => taps++),
      );

      // It used to be handed an empty closure, which left Material treating it
      // as enabled: it rippled and took focus while doing nothing.
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
        isFalse,
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('but keeps its own colours, unlike a disabled one', (
      tester,
    ) async {
      final ColorScheme scheme = AppTheme.light().colorScheme;

      await pumpInBox(
        tester,
        CustomButton(text: 'Save', isLoading: true, onPressed: () {}),
      );

      final ButtonStyle? style = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .style;

      // Loading reads as busy, not as unavailable, so the brand background
      // stays and the spinner stays legible on it.
      expect(
        style?.backgroundColor?.resolve({WidgetState.disabled}),
        scheme.primary,
      );
    });

    testWidgets('a genuinely disabled button still greys out', (tester) async {
      await pumpInBox(
        tester,
        const CustomButton(text: 'Save', onPressed: null),
      );

      final ButtonStyle? style = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .style;

      // Left unset, so Material's own disabled colours apply.
      expect(style?.backgroundColor?.resolve({WidgetState.disabled}), isNull);
    });
  });

  group('width', () {
    // Wrapped in an Align, which passes loose constraints. The SizedBox in
    // pumpInBox alone is a tight width, and a tight constraint overrides
    // whatever the button asks for — so both cases would measure 200 and the
    // test would prove nothing.
    Widget loose(Widget child) =>
        Align(alignment: Alignment.centerLeft, child: child);

    testWidgets('fills what it is offered by default', (tester) async {
      await pumpInBox(tester, loose(CustomButton(text: 'OK', onPressed: () {})));

      expect(tester.getSize(find.byType(ElevatedButton)).width, 200);
    });

    testWidgets('sizes to its label when told not to fill', (tester) async {
      await pumpInBox(
        tester,
        loose(CustomButton(text: 'OK', fullWidth: false, onPressed: () {})),
      );

      expect(tester.getSize(find.byType(ElevatedButton)).width, lessThan(200));
    });

    testWidgets('two of them fit side by side in a Row', (tester) async {
      // The whole point of fullWidth: false. With the old forced
      // double.infinity this threw, because two infinite children cannot
      // share a bounded Row.
      await pumpInBox(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: 'Cancel',
              fullWidth: false,
              type: ButtonType.outlined,
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacings.wSm),
            CustomButton(text: 'Save', fullWidth: false, onPressed: () {}),
          ],
        ),
        width: 400,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  testWidgets('its corners match the ones AppTheme gives Material buttons', (
    tester,
  ) async {
    // These were AppRadius.md while the theme used AppRadius.lg, so a
    // CustomButton and a FilledButton on one screen had different corners.
    await pumpInBox(tester, CustomButton(text: 'OK', onPressed: () {}));

    final RoundedRectangleBorder shape =
        tester
                .widget<ElevatedButton>(find.byType(ElevatedButton))
                .style
                ?.shape
                ?.resolve({})
            as RoundedRectangleBorder;

    expect(shape.borderRadius, BorderRadius.circular(AppRadius.lg));
  });
}
