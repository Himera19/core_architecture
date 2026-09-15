import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'router.dart';
import 'showcase/pulsing_dots.dart';

const String appName = 'core_architecture';

/// The one colour the whole design system is re-branded from.
const Color brandColor = Color.fromARGB(255, 93, 27, 154);

Future<void> main() async {
  await CoreInitializer.quickStart(appName: appName);
  runApp(const ProviderScope(child: HobbyApp()));
}

class HobbyApp extends ConsumerWidget {
  const HobbyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No fontFamily: 'Inter' is not registered in this app's pubspec, so
    // asking for it would resolve to the platform default anyway.
    return MaterialApp.router(
      title: appName,
      routerConfig: appRouter,
      theme: AppTheme.light(
        brandColor: brandColor,
        loadingIndicatorBuilder: loadingIndicator,
      ),
      darkTheme: AppTheme.dark(
        brandColor: brandColor,
        loadingIndicatorBuilder: loadingIndicator,
      ),
      themeMode: ref.watch(themeProvider),
    );
  }
}

/// The spinner every [CustomButton] in this app shows while loading.
///
/// Installed once on the theme, so no call site asks for it. The package
/// hands it the button's own foreground colour, which is why one builder
/// serves every [ButtonType].
Widget loadingIndicator(BuildContext context, Color color) =>
    PulsingDots(color: color);
