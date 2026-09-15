import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../showcase/section.dart';

/// Every shipped widget, plus a real [Form] that runs them through
/// [Validators] — the path where the multi-select validator used to be dead.
class WidgetsScreen extends StatefulWidget {
  const WidgetsScreen({super.key});

  static const String path = '/widgets';

  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _city;
  String? _country;
  List<String> _tags = const [];

  static const List<String> _cities = ['Ankara', 'Bursa', 'İstanbul', 'İzmir'];
  static const List<String> _countries = [
    'Türkiye',
    'Almanya',
    'Fransa',
    'Hollanda',
    'İspanya',
    'İtalya',
    'Portekiz',
    'Yunanistan',
  ];
  static const List<String> _tagOptions = [
    'flutter',
    'dart',
    'riverpod',
    'design system',
    'testing',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Validates the text fields and both dropdowns in one pass.
    if (_formKey.currentState!.validate()) {
      context.showSuccess('Form is valid');
    } else {
      context.showError('Fix the highlighted fields');
    }
  }

  Future<void> _runLoading() async {
    setState(() => _loading = true);
    await Future<void>.delayed(AppDurations.splash);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;

    return ShowcasePage(
      title: 'Widgets',
      sections: [
        Section(
          title: 'Button types',
          api: 'CustomButton · ButtonType',
          children: [
            CustomButton(text: 'primary', onPressed: () {}),
            Gap.hSm,
            CustomButton(
              text: 'secondary',
              type: ButtonType.secondary,
              onPressed: () {},
            ),
            Gap.hSm,
            CustomButton(
              text: 'outlined',
              type: ButtonType.outlined,
              onPressed: () {},
            ),
            Gap.hSm,
            CustomButton(
              text: 'danger',
              type: ButtonType.danger,
              onPressed: () {},
            ),
            Gap.hSm,
            // A null callback is the disabled state.
            const CustomButton(text: 'disabled', onPressed: null),
            Gap.hLg,
            Text(
              'Full width is the default, but two buttons can share a row. '
              'Before 6.0.0 the width was forced, so this took an Expanded '
              'around each one.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Gap.hSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Cancel',
                  fullWidth: false,
                  type: ButtonType.outlined,
                  onPressed: () {},
                ),
                Gap.wSm,
                CustomButton(
                  text: 'Save',
                  fullWidth: false,
                  icon: Icons.check,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),

        Section(
          title: 'Button sizes, icons and loading',
          api: 'ButtonSize · icon · isLoading',
          children: [
            CustomButton(
              text: 'small',
              size: ButtonSize.small,
              onPressed: () {},
            ),
            Gap.hSm,
            CustomButton(
              text: 'medium',
              onPressed: () {},
            ),
            Gap.hSm,
            CustomButton(text: 'large', size: ButtonSize.large, onPressed: () {}),
            Gap.hSm,
            CustomButton(
              text: 'with icon',
              icon: Icons.favorite,
              onPressed: () {},
            ),
            Gap.hSm,
            CustomButton(
              text: _loading ? 'loading…' : 'run for 2s',
              isLoading: _loading,
              onPressed: _runLoading,
            ),
          ],
        ),

        Section(
          title: 'Text fields',
          api: 'CustomTextField',
          children: [
            const CustomTextField(label: 'Plain', hint: 'type something'),
            Gap.hSm,
            const CustomTextField(
              label: 'With icons',
              prefixIcon: Icons.person,
              suffixIcon: Icons.check,
            ),
            Gap.hSm,
            const CustomTextField(
              label: 'Password',
              obscureText: true,
              showPasswordToggle: true,
              prefixIcon: Icons.lock,
            ),
            Gap.hSm,
            CustomTextField(
              label: 'Digits only',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: Icons.tag,
            ),
            Gap.hSm,
            const CustomTextField(
              label: 'Multiline',
              maxLines: 3,
              hint: 'three lines tall',
            ),
            Gap.hSm,
            const CustomTextField(
              label: 'Read only',
              readOnly: true,
              initialValue: 'cannot be edited',
            ),
            Gap.hSm,
            const CustomTextField(
              label: 'Disabled',
              enabled: false,
              initialValue: 'greyed out',
            ),
          ],
        ),

        Section(
          title: 'Dropdowns',
          api: 'CustomDropdown · CustomDropdownType',
          children: [
            CustomDropdown<String>(
              label: 'City',
              hintText: 'Pick a city',
              searchHint: 'Search',
              noResultsText: 'Nothing matched',
              items: _cities,
              itemLabel: (item) => item,
              value: _city,
              icon: Icons.location_city,
              onChanged: (value) => setState(() => _city = value),
            ),
            Gap.hSm,
            // Searchable opens the same sheet with a filter field on top.
            CustomDropdown<String>(
              label: 'Country',
              hintText: 'Pick a country (searchable)',
              searchHint: 'Type to filter',
              noResultsText: 'Nothing matched',
              type: CustomDropdownType.searchable,
              items: _countries,
              itemLabel: (item) => item,
              value: _country,
              icon: Icons.public,
              onChanged: (value) => setState(() => _country = value),
            ),
            Gap.hSm,
            Readout('selected', '${_city ?? '—'} · ${_country ?? '—'}'),
            Gap.hXs,
            Text(
              'The arrow on the field, the magnifier in the searchable sheet '
              'and its clear button all come from CustomDropdownConstants — '
              'reuse them to match a dropdown you build yourself.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),

        Section(
          title: 'Multi-select, capped at three',
          api: 'CustomMultiSelectDropdown · maxSelections',
          children: [
            CustomMultiSelectDropdown<String>(
              label: 'Tags',
              hintText: 'Pick tags',
              selectedCountSuffix: 'selected',
              clearLabel: 'Clear',
              confirmLabel: 'Done',
              maxSelectionMessage: 'Three at most',
              items: _tagOptions,
              itemLabel: (item) => item,
              initialValues: _tags,
              maxSelections: 3,
              icon: Icons.label,
              onChanged: (values) => setState(() => _tags = values),
            ),
            Gap.hSm,
            Readout('selected', _tags.isEmpty ? '—' : _tags.join(', ')),
          ],
        ),

        Section(
          title: 'A form that actually validates',
          api: 'Validators · Form.validate() · context.showSuccess/showError',
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.mail,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        Validators.email(value, errorMessage: 'Invalid email'),
                  ),
                  Gap.hSm,
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    showPasswordToggle: true,
                    prefixIcon: Icons.lock,
                    // compose runs the rules in order and reports the first
                    // failure.
                    validator: Validators.compose([
                      (value) => Validators.required(
                        value,
                        errorMessage: 'Password is required',
                      ),
                      (value) => Validators.minLength(
                        value,
                        8,
                        errorMessage: 'At least 8 characters',
                      ),
                    ]),
                  ),
                  Gap.hSm,
                  CustomTextField(
                    label: 'Confirm password',
                    obscureText: true,
                    showPasswordToggle: true,
                    validator: (value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                      errorMessage: 'Passwords do not match',
                    ),
                  ),
                  Gap.hSm,
                  CustomTextField(
                    label: 'Phone',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone,
                    validator: (value) =>
                        Validators.phone(value, errorMessage: 'Invalid phone'),
                  ),
                  Gap.hSm,
                  CustomTextField(
                    label: 'Website',
                    keyboardType: TextInputType.url,
                    prefixIcon: Icons.link,
                    validator: (value) =>
                        Validators.url(value, errorMessage: 'Invalid URL'),
                  ),
                  Gap.hSm,
                  CustomTextField(
                    label: 'Amount',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.payments,
                    validator: (value) => Validators.amount(
                      value,
                      errorMessage: 'Must be greater than zero',
                    ),
                  ),
                  Gap.hSm,
                  CustomDropdown<String>(
                    label: 'Required city',
                    hintText: 'Required city',
                    searchHint: 'Search',
                    noResultsText: 'Nothing matched',
                    items: _cities,
                    itemLabel: (item) => item,
                    validator: (value) =>
                        value == null ? 'City is required' : null,
                  ),
                  Gap.hSm,
                  CustomMultiSelectDropdown<String>(
                    label: 'Required tags',
                    hintText: 'Required tags',
                    selectedCountSuffix: 'selected',
                    clearLabel: 'Clear',
                    confirmLabel: 'Done',
                    maxSelectionMessage: 'Three at most',
                    items: _tagOptions,
                    itemLabel: (item) => item,
                    maxSelections: 3,
                    // Before 4.0.0 this validator only ever saw null, so the
                    // form could not be submitted however many tags were
                    // ticked.
                    validator: (values) => (values == null || values.isEmpty)
                        ? 'Pick at least one tag'
                        : null,
                  ),
                  Gap.hMd,
                  CustomButton(
                    text: 'Validate',
                    icon: Icons.check_circle,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),

        Section(
          title: 'Snackbars',
          api: 'context.showSuccess / showError / showInfo',
          children: [
            CustomButton(
              text: 'showSuccess',
              size: ButtonSize.small,
              onPressed: () => context.showSuccess('Saved'),
            ),
            Gap.hXs,
            CustomButton(
              text: 'showError',
              type: ButtonType.danger,
              size: ButtonSize.small,
              onPressed: () => context.showError('Something broke'),
            ),
            Gap.hXs,
            CustomButton(
              text: 'showInfo',
              type: ButtonType.outlined,
              size: ButtonSize.small,
              onPressed: () => context.showInfo('Just so you know'),
            ),
          ],
        ),

        Section(
          title: 'Loading, and bringing your own spinner',
          api: 'isLoading · loadingIndicator · AppTheme(loadingIndicatorBuilder)',
          children: [
            Text(
              'This app sets loadingIndicatorBuilder on its theme, so every '
              'button below shows the dots it draws itself — no call site asks '
              'for them, and the package brings no animation library.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Gap.hSm,
            // The builder is handed each button's own foreground, so one
            // builder covers all four types.
            for (final type in ButtonType.values) ...[
              CustomButton(
                text: type.name,
                type: type,
                isLoading: true,
                onPressed: () {},
              ),
              Gap.hXs,
            ],
            Gap.hSm,
            Text(
              'A single button can still override it.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Gap.hSm,
            CustomButton(
              text: 'this one only',
              isLoading: true,
              loadingIndicator: const SizedBox(
                height: AppSizes.iconMd,
                width: AppSizes.iconMd,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              onPressed: () {},
            ),
            Gap.hSm,
            Text(
              'A loading button is also inert: it keeps its colour but stops '
              'answering taps, focus and the keyboard.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

