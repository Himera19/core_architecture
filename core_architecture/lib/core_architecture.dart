library;

// ==================== Core ====================
// Config
export 'src/core/config/core_initializer.dart';
export 'src/core/core_providers.dart';

// Entities
export 'src/core/entities/base_entity.dart';

// Errors
export 'src/core/errors/failures.dart';
export 'src/core/errors/exceptions.dart';

// Logging
export 'src/core/logging/logger_service.dart';

// Providers
export 'src/providers/theme_provider.dart';
export 'src/providers/onboarding_provider.dart';

// ==================== Backend Contracts ====================
export 'src/backends/contracts/crud_contract.dart';

// ==================== Services ====================
export 'src/services/storage_service.dart';
export 'src/services/secure_storage_service.dart';

// ==================== UI Layer ====================
// Themes
export 'src/ui/themes/light_theme.dart';
export 'src/ui/themes/dark_theme.dart';
export 'src/ui/themes/app_color_scheme.dart';

// Tokens
export 'src/ui/tokens/app_borders.dart';
export 'src/ui/tokens/app_colors.dart';
export 'src/ui/tokens/app_durations.dart';
export 'src/ui/tokens/app_radius.dart';
export 'src/ui/tokens/app_sizes.dart';
export 'src/ui/tokens/app_spacings.dart';
export 'src/ui/tokens/app_typography.dart';
export 'src/ui/tokens/app_opacities.dart';
export 'src/ui/tokens/app_elevations.dart';

// Responsive
export 'src/ui/responsive/app_breakpoints.dart';
export 'src/ui/responsive/responsive_builder.dart';
export 'src/ui/responsive/responsive_value.dart';
export 'src/ui/responsive/platform_info.dart';

// Widgets
export 'src/ui/widgets/custom_app_bar.dart';
export 'src/ui/widgets/custom_button.dart';
export 'src/ui/widgets/custom_text_field.dart';
export 'src/ui/widgets/custom_dropdown.dart';
export 'src/ui/widgets/navbar.dart';

// ==================== Utils ====================
export 'src/utils/border_utils.dart';
export 'src/utils/currency_helper.dart';
export 'src/utils/date_helper.dart';
export 'src/utils/gap_utils.dart';
export 'src/utils/input_formatters.dart';
export 'src/utils/radius_utils.dart';
export 'src/utils/spacing_utils.dart';
export 'src/utils/spin_kit_indicator.dart';
export 'src/utils/url_launcher.dart';
export 'src/utils/validators.dart';

// Extensions
export 'src/utils/extensions/context_extensions.dart';

// ==================== Optional Modules ====================
// Purchase (requires purchases_flutter — remove if not needed)
export 'src/core/errors/purchase_failure.dart';

// ==================== External Packages (Re-export) ====================
export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:go_router/go_router.dart';
