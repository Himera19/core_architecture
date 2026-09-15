import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mounts [child] in a box narrower than its natural width, which is where a
/// full-width button meets a label it cannot fit.
Future<void> pumpInBox(
  WidgetTester tester,
  Widget child, {
  double width = 200,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
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

        expect(tester.takeException(), isNull, reason: '${size.name} overflowed');
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
      await pumpInBox(
        tester,
        CustomButton(text: 'Save', onPressed: () {}),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Save'), findsOneWidget);
    });
  });
}
