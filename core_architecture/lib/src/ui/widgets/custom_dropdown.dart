import 'package:flutter/material.dart';

import '../tokens/app_borders.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacings.dart';
import '../../utils/extensions/context_extensions.dart';
import '../../utils/gap_utils.dart';
import '../../utils/spacing_utils.dart';
import 'custom_button.dart';

class CustomDropdownConstants {
  static const IconData dropdown = Icons.arrow_drop_down;
  static const IconData search = Icons.search;
  static const IconData clear = Icons.clear;
}

enum CustomDropdownType { normal, searchable, multiSelect }

class CustomDropdown<T> extends StatefulWidget {
  final String label;
  final String hintText;
  final String searchHint;
  final String noResultsText;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?)? onChanged;
  final CustomDropdownType type;
  final String? Function(T?)? validator;
  final bool enabled;
  final IconData? icon;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.searchHint,
    required this.noResultsText,
    required this.items,
    required this.itemLabel,
    this.value,
    this.onChanged,
    this.type = CustomDropdownType.normal,
    this.validator,
    this.enabled = true,
    this.icon,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  T? _selectedValue;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  @override
  void didUpdateWidget(CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _selectedValue = widget.value;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showDropdownMenu(FormFieldState<T> fieldState) {
    final colors = context.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DropdownBottomSheet<T>(
        items: widget.items,
        itemLabel: widget.itemLabel,
        selectedValue: _selectedValue,
        type: widget.type,
        onChanged: (value) {
          setState(() {
            _selectedValue = value;
          });

          fieldState.didChange(value);

          widget.onChanged?.call(value);
        },
        colorScheme: colors,
        searchHint: widget.searchHint,
        noResultsText: widget.noResultsText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final TextTheme textTheme = context.textTheme;

    return FormField<T>(
      initialValue: _selectedValue,
      validator: widget.validator,
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.enabled
                  ? () => _showDropdownMenu(fieldState)
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.hintText,
                  hintText: widget.hintText,
                  prefixIcon: widget.icon == null
                      ? null
                      : Icon(
                          widget.icon,
                          size: AppSizes.iconMd,
                          color: colors.primary,
                        ),
                  suffixIcon: Icon(
                    CustomDropdownConstants.dropdown,
                    color: colors.onSurfaceVariant,
                    size: AppSizes.iconMd,
                  ),
                  filled: true,
                  fillColor: widget.enabled
                      ? colors.surfaceContainerHighest
                      : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: colors.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: AppBorders.normal,
                    ),
                  ),
                  contentPadding:
                      SpacingUtils.horizontal(AppSpacings.wMd) +
                      SpacingUtils.vertical(AppSpacings.hSm),
                  errorText: fieldState.hasError ? fieldState.errorText : null,
                ),
                isEmpty: _selectedValue == null,
                child: Text(
                  _selectedValue != null
                      ? widget.itemLabel(_selectedValue as T)
                      : '',
                  style: textTheme.bodyLarge?.copyWith(
                    color: _selectedValue != null
                        ? colors.onSurface
                        : colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DropdownBottomSheet<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final T? selectedValue;
  final CustomDropdownType type;
  final void Function(T?) onChanged;
  final ColorScheme colorScheme;
  final String searchHint;
  final String noResultsText;

  const _DropdownBottomSheet({
    required this.items,
    required this.itemLabel,
    required this.selectedValue,
    required this.type,
    required this.onChanged,
    required this.colorScheme,
    required this.searchHint,
    required this.noResultsText,
  });

  @override
  State<_DropdownBottomSheet<T>> createState() =>
      _DropdownBottomSheetState<T>();
}

class _DropdownBottomSheetState<T> extends State<_DropdownBottomSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (widget.type != CustomDropdownType.searchable || _searchQuery.isEmpty) {
      return widget.items;
    }

    return widget.items.where((item) {
      final label = widget.itemLabel(item).toLowerCase();
      return label.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: SpacingUtils.onlyTop(AppSpacings.hSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),

          Gap.hMd,

          if (widget.type == CustomDropdownType.searchable) ...[
            Padding(
              padding: SpacingUtils.horizontal(AppSpacings.wMd),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    CustomDropdownConstants.search,
                    color: colors.primary,
                    size: AppSizes.iconMd,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            CustomDropdownConstants.clear,
                            color: colors.onSurfaceVariant,
                            size: AppSizes.iconMd,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: colors.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: AppBorders.normal,
                    ),
                  ),
                  contentPadding:
                      SpacingUtils.horizontal(AppSpacings.wMd) +
                      SpacingUtils.vertical(AppSpacings.hSm),
                ),
              ),
            ),
            Gap.hMd,
          ],

          Flexible(
            child: _filteredItems.isEmpty
                ? SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: SpacingUtils.all(AppSpacings.wLg),
                      child: Text(
                        widget.noResultsText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    padding: SpacingUtils.onlyBottom(AppSpacings.hLg),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item == widget.selectedValue;

                      return InkWell(
                        onTap: () {
                          widget.onChanged(item);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding:
                              SpacingUtils.horizontal(AppSpacings.wMd) +
                              SpacingUtils.vertical(AppSpacings.hSm),
                          color: isSelected
                              ? colors.primaryContainer.withValues(alpha: 0.3)
                              : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.itemLabel(item),
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: colors.primary,
                                  size: AppSizes.iconMd,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomMultiSelectDropdown<T> extends StatefulWidget {
  final String label;
  final String hintText;
  final String selectedCountSuffix;
  final String clearLabel;
  final String confirmLabel;
  final String maxSelectionMessage;
  final List<T> items;
  final String Function(T) itemLabel;
  final List<T> initialValues;
  final void Function(List<T>)? onChanged;
  final String? Function(List<T>?)? validator;
  final bool enabled;
  final IconData? icon;
  final int? maxSelections;

  const CustomMultiSelectDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.selectedCountSuffix,
    required this.clearLabel,
    required this.confirmLabel,
    required this.maxSelectionMessage,
    required this.items,
    required this.itemLabel,
    this.initialValues = const [],
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.icon,
    this.maxSelections,
  });

  @override
  State<CustomMultiSelectDropdown<T>> createState() =>
      _CustomMultiSelectDropdownState<T>();
}

class _CustomMultiSelectDropdownState<T>
    extends State<CustomMultiSelectDropdown<T>> {
  late List<T> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.initialValues);
  }

  void _showMultiSelectMenu() {
    final colors = context.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MultiSelectBottomSheet<T>(
        items: widget.items,
        itemLabel: widget.itemLabel,
        selectedValues: _selectedValues,
        onChanged: (values) {
          setState(() {
            _selectedValues = values;
          });
          widget.onChanged?.call(values);
        },
        colorScheme: colors,
        maxSelections: widget.maxSelections,
        selectedCountSuffix: widget.selectedCountSuffix,
        clearLabel: widget.clearLabel,
        confirmLabel: widget.confirmLabel,
        maxSelectionMessage: widget.maxSelectionMessage,
      ),
    );
  }

  String get _displayText {
    if (_selectedValues.isEmpty) return widget.hintText;
    if (_selectedValues.length == 1) {
      return widget.itemLabel(_selectedValues.first);
    }
    return '${_selectedValues.length} ${widget.selectedCountSuffix}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final TextTheme textTheme = context.textTheme;

    return FormField<List<T>>(
      validator: widget.validator,
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: widget.hintText,
                hintText: widget.hintText,
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                prefixIcon: widget.icon == null
                    ? null
                    : Icon(
                        widget.icon,
                        size: AppSizes.iconMd,
                        color: colors.primary,
                      ),
                suffixIcon: Icon(
                  CustomDropdownConstants.dropdown,
                  color: colors.onSurfaceVariant,
                  size: AppSizes.iconMd,
                ),
                filled: true,
                fillColor: widget.enabled
                    ? colors.surfaceContainerHighest
                    : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: colors.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: colors.primary,
                    width: AppBorders.normal,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: colors.error,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: colors.error,
                    width: AppBorders.normal,
                  ),
                ),
                contentPadding:
                    SpacingUtils.horizontal(AppSpacings.wMd) +
                    SpacingUtils.vertical(AppSpacings.hSm),
                errorText: fieldState.hasError ? fieldState.errorText : null,
              ),
              isEmpty: _selectedValues.isEmpty,
              child: InkWell(
                onTap: widget.enabled ? _showMultiSelectMenu : null,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Text(
                  _displayText,
                  style: textTheme.bodyLarge?.copyWith(
                    color: _selectedValues.isNotEmpty
                        ? colors.onSurface
                        : colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MultiSelectBottomSheet<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final List<T> selectedValues;
  final void Function(List<T>) onChanged;
  final ColorScheme colorScheme;
  final int? maxSelections;
  final String selectedCountSuffix;
  final String clearLabel;
  final String confirmLabel;
  final String maxSelectionMessage;

  const _MultiSelectBottomSheet({
    required this.items,
    required this.itemLabel,
    required this.selectedValues,
    required this.onChanged,
    required this.colorScheme,
    required this.selectedCountSuffix,
    required this.clearLabel,
    required this.confirmLabel,
    required this.maxSelectionMessage,
    this.maxSelections,
  });

  @override
  State<_MultiSelectBottomSheet<T>> createState() =>
      _MultiSelectBottomSheetState<T>();
}

class _MultiSelectBottomSheetState<T>
    extends State<_MultiSelectBottomSheet<T>> {
  late List<T> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedValues);
  }

  void _toggleSelection(T item) {
    setState(() {
      if (_tempSelected.contains(item)) {
        _tempSelected.remove(item);
      } else {
        if (widget.maxSelections != null &&
            _tempSelected.length >= widget.maxSelections!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.maxSelectionMessage),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _tempSelected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: SpacingUtils.onlyTop(AppSpacings.hSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),

          Gap.hMd,

          Padding(
            padding: SpacingUtils.horizontal(AppSpacings.wMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_tempSelected.length} ${widget.selectedCountSuffix}',
                  style: textTheme.titleMedium,
                ),
                if (_tempSelected.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempSelected.clear();
                      });
                    },
                    child: Text(widget.clearLabel),
                  ),
              ],
            ),
          ),

          Gap.hSm,
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.items.length,
              padding: SpacingUtils.onlyBottom(AppSpacings.hLg),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = _tempSelected.contains(item);

                return InkWell(
                  onTap: () => _toggleSelection(item),
                  child: Container(
                    padding:
                        SpacingUtils.horizontal(AppSpacings.wMd) +
                        SpacingUtils.vertical(AppSpacings.hSm),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(item),
                          activeColor: colors.primary,
                        ),
                        Gap.hSm,
                        Expanded(
                          child: Text(
                            widget.itemLabel(item),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: SpacingUtils.all(AppSpacings.wMd),
            child: CustomButton(
              text: widget.confirmLabel,
              onPressed: () {
                widget.onChanged(_tempSelected);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
