import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {GlobalKey<FormState>? formKey}) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Form(key: formKey, child: child)),
);

void main() {
  group('CustomMultiSelectDropdown validation', () {
    // The FormField used to be built with neither an initialValue nor a
    // didChange call, so validator() only ever saw null: a "pick at least one"
    // rule failed however many items the user had ticked.
    testWidgets('validator sees the initial values', (tester) async {
      final formKey = GlobalKey<FormState>();
      List<String>? seenByValidator;

      await tester.pumpWidget(
        _host(
          formKey: formKey,
          CustomMultiSelectDropdown<String>(
            label: 'Tags',
            hintText: 'Pick tags',
            selectedCountSuffix: 'selected',
            clearLabel: 'Clear',
            confirmLabel: 'Done',
            maxSelectionMessage: 'Too many',
            items: const ['a', 'b', 'c'],
            itemLabel: (item) => item,
            initialValues: const ['a'],
            validator: (values) {
              seenByValidator = values;
              return (values == null || values.isEmpty) ? 'required' : null;
            },
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isTrue);
      expect(seenByValidator, ['a']);
    });

    testWidgets('validator sees values picked in the sheet', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        _host(
          formKey: formKey,
          CustomMultiSelectDropdown<String>(
            label: 'Tags',
            hintText: 'Pick tags',
            selectedCountSuffix: 'selected',
            clearLabel: 'Clear',
            confirmLabel: 'Done',
            maxSelectionMessage: 'Too many',
            items: const ['a', 'b', 'c'],
            itemLabel: (item) => item,
            validator: (values) =>
                (values == null || values.isEmpty) ? 'required' : null,
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);

      // Tapping the arrow, not the label: the InkWell used to sit inside the
      // decorator, so only the text opened the sheet.
      await tester.tap(find.byIcon(CustomDropdownConstants.dropdown));
      await tester.pumpAndSettle();

      await tester.tap(find.text('b').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('the confirmed list is a copy, not the sheet\'s own', (
      tester,
    ) async {
      List<String>? delivered;

      await tester.pumpWidget(
        _host(
          CustomMultiSelectDropdown<String>(
            label: 'Tags',
            hintText: 'Pick tags',
            selectedCountSuffix: 'selected',
            clearLabel: 'Clear',
            confirmLabel: 'Done',
            maxSelectionMessage: 'Too many',
            items: const ['a', 'b'],
            itemLabel: (item) => item,
            onChanged: (values) => delivered = values,
          ),
        ),
      );

      await tester.tap(find.byIcon(CustomDropdownConstants.dropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text('a').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(delivered, ['a']);

      // Reopening and ticking more must not reach back into the delivered list.
      await tester.tap(find.byIcon(CustomDropdownConstants.dropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text('b').last);
      await tester.pumpAndSettle();

      expect(delivered, ['a']);
    });
  });

  group('bottom sheets clear the keyboard', () {
    testWidgets('searchable sheet is inset by the view insets', (tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          CustomDropdown<String>(
            label: 'City',
            hintText: 'Pick a city',
            searchHint: 'Search',
            noResultsText: 'Nothing found',
            items: const ['Ankara', 'Bursa'],
            itemLabel: (item) => item,
          ),
        ),
      );

      await tester.tap(find.byIcon(CustomDropdownConstants.dropdown));
      await tester.pumpAndSettle();

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Padding),
            )
            .first,
      );

      expect(
        (padding.padding as EdgeInsets).bottom,
        300 / tester.view.devicePixelRatio,
      );
    });
  });
}
