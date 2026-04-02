import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Not: Bu importlar sizin projenize özel tokenlardır.
// Hata almamak için kendi projenizdeki yolları kontrol edin.
import '../tokens/app_borders.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacings.dart';
import '../tokens/app_typography.dart';
import '../../utils/extensions/context_extensions.dart';
import '../../utils/spacing_utils.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  // Input configuration
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;

  // Visual configuration
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final bool showPasswordToggle;

  final String? initialValue;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.initialValue,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;

    if (widget.controller != null &&
        widget.initialValue != null &&
        widget.controller!.text.isEmpty) {
      widget.controller!.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final TextTheme textTheme = context.textTheme;

    // Web üzerinde hover/error durumunda yazı renginin kaybolmasını engellemek için
    // stilleri önceden tanımlıyoruz.
    final TextStyle commonTextStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: textTheme.bodyLarge?.fontSize,
    );

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      // Ana yazı stili
      style: commonTextStyle.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: widget.label,
        // Label normal durumdayken
        labelStyle: commonTextStyle.copyWith(color: colors.onSurfaceVariant),
        // Hata varken yukarıdaki label'ın rengi (Web hover sorununu çözer)
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return commonTextStyle.copyWith(color: colors.error);
          }
          if (states.contains(WidgetState.focused)) {
            return commonTextStyle.copyWith(color: colors.primary);
          }
          return commonTextStyle.copyWith(color: colors.onSurfaceVariant);
        }),
        hintText: widget.hint,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          fontFamily: AppTypography.fontFamily,
        ),
        // Hata mesajı yazı stili
        errorStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: colors.error,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(
                widget.prefixIcon,
                size: AppSizes.iconMd,
                color: colors.primary,
              ),
        suffixIcon: widget.showPasswordToggle
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: colors.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : (widget.suffixIcon == null
                  ? null
                  : Icon(
                      widget.suffixIcon,
                      size: AppSizes.iconMd,
                      color: colors.onSurfaceVariant,
                    )),
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
          borderSide: BorderSide(color: colors.outlineVariant),
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
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.error, width: AppBorders.normal),
        ),
        contentPadding:
            SpacingUtils.horizontal(AppSpacings.wMd) +
            SpacingUtils.vertical(AppSpacings.hSm),
      ),
    );
  }
}
