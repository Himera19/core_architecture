import 'package:go_router/go_router.dart';
import 'screens/domain_screen.dart';
import 'screens/home_screen.dart';
import 'screens/responsive_screen.dart';
import 'screens/storage_screen.dart';
import 'screens/theme_screen.dart';
import 'screens/tokens_screen.dart';
import 'screens/utils_screen.dart';
import 'screens/widgets_screen.dart';

/// Every showcase page, one route each.
///
/// The paths double as the list on [HomeScreen], so adding a page here is the
/// only step needed to surface it.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: ThemeScreen.path,
      builder: (context, state) => const ThemeScreen(),
    ),
    GoRoute(
      path: TokensScreen.path,
      builder: (context, state) => const TokensScreen(),
    ),
    GoRoute(
      path: WidgetsScreen.path,
      builder: (context, state) => const WidgetsScreen(),
    ),
    GoRoute(
      path: ResponsiveScreen.path,
      builder: (context, state) => const ResponsiveScreen(),
    ),
    GoRoute(
      path: StorageScreen.path,
      builder: (context, state) => const StorageScreen(),
    ),
    GoRoute(
      path: UtilsScreen.path,
      builder: (context, state) => const UtilsScreen(),
    ),
    GoRoute(
      path: DomainScreen.path,
      builder: (context, state) => const DomainScreen(),
    ),
  ],
);
