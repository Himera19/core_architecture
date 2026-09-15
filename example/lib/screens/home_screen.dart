import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import 'domain_screen.dart';
import 'responsive_screen.dart';
import 'storage_screen.dart';
import 'theme_screen.dart';
import 'tokens_screen.dart';
import 'utils_screen.dart';
import 'widgets_screen.dart';

/// Index of the showcase: one entry per area of core_architecture.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<({String title, String subtitle, IconData icon, String path})>
  destinations = [
    (
      title: 'Theme',
      subtitle: 'AppTheme, colour schemes, themeProvider, the type ramp',
      icon: Icons.palette,
      path: ThemeScreen.path,
    ),
    (
      title: 'Tokens',
      subtitle: 'Spacing, radius, sizes, borders, elevation, opacity, duration',
      icon: Icons.straighten,
      path: TokensScreen.path,
    ),
    (
      title: 'Widgets',
      subtitle: 'Buttons, text fields, dropdowns, a validating form, snackbars',
      icon: Icons.widgets,
      path: WidgetsScreen.path,
    ),
    (
      title: 'Responsive',
      subtitle: 'Breakpoints, ResponsiveBuilder, ResponsiveValue, PlatformInfo',
      icon: Icons.devices,
      path: ResponsiveScreen.path,
    ),
    (
      title: 'Storage & providers',
      subtitle: 'StorageService, onboarding, logging, CoreInitializer',
      icon: Icons.storage,
      path: StorageScreen.path,
    ),
    (
      title: 'Utils',
      subtitle: 'DateHelper, Validators, SpacingUtils, UrlLauncher',
      icon: Icons.handyman,
      path: UtilsScreen.path,
    ),
    (
      title: 'Domain',
      subtitle: 'BaseEntity, CrudContract, failures and exceptions',
      icon: Icons.account_tree,
      path: DomainScreen.path,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colorScheme;
    final ThemeMode mode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [
          IconButton(
            tooltip: 'Toggle theme (now: ${mode.name})',
            icon: const Icon(Icons.brightness_6),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: SpacingUtils.all(
            ResponsiveSpacings.pagePadding.resolve(context),
          ),
          child: Center(
            child: ConstrainedBox(
              // Keeps the list readable on a wide desktop window.
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'core_architecture showcase',
                    style: AppTypography.headlineSm,
                  ),
                  Gap.hXxs,
                  Text(
                    'Every exported feature, running. Brand colour '
                    '${_hex(brandColor)} seeds the accents; the neutrals are '
                    'the design system\'s own.',
                    style: AppTypography.bodySm.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Gap.hLg,
                  // One column on a phone, two once there is room.
                  ResponsiveBuilder(
                    compact: (context) => const _Destinations(columns: 1),
                    medium: (context) => const _Destinations(columns: 2),
                    expanded: (context) => const _Destinations(columns: 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class _Destinations extends StatelessWidget {
  const _Destinations({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [
      for (final destination in HomeScreen.destinations)
        _DestinationCard(destination: destination),
    ];

    if (columns == 1) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: cards);
    }

    // Rows of [columns] cards, the last one padded out so the widths match.
    final List<Widget> rows = [];
    for (int i = 0; i < cards.length; i += columns) {
      final List<Widget> slice = cards.sublist(
        i,
        (i + columns).clamp(0, cards.length),
      );
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final card in slice) Expanded(child: card),
              for (int pad = slice.length; pad < columns; pad++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination});

  final ({String title, String subtitle, IconData icon, String path})
  destination;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;

    return Padding(
      padding: SpacingUtils.all(AppSpacings.rXxs),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(destination.path),
          child: Padding(
            padding: SpacingUtils.all(AppSpacings.rMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      destination.icon,
                      color: colors.primary,
                      size: AppSizes.iconMd,
                    ),
                    Gap.wSm,
                    Expanded(
                      child: Text(
                        destination.title,
                        style: AppTypography.titleMd,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: AppSizes.iconSm,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
                Gap.hXs,
                Text(
                  destination.subtitle,
                  style: AppTypography.bodySm.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
