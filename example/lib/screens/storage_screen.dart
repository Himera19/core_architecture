import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../showcase/section.dart';

/// The service layer: the two storage providers doing real reads and writes,
/// [onboardingStateProvider], [loggerServiceProvider] and [CoreInitializer].
class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  static const String path = '/storage';

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  final TextEditingController _keyController = TextEditingController(
    text: 'demo_key',
  );
  final TextEditingController _valueController = TextEditingController(
    text: 'demo value',
  );

  /// Last result of a storage call, or the failure it threw.
  String _result = 'no call yet';

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  /// Runs [action] and reports whatever comes back — including the
  /// [LocalStorageException] the service raises when the platform has no
  /// keystore, which is the honest outcome on an unsupported target.
  Future<void> _run(String label, Future<String?> Function() action) async {
    try {
      final String? value = await action();
      if (!mounted) return;
      setState(() => _result = '$label → ${value ?? 'null'}');
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      setState(() => _result = '$label → ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Two stores, on purpose. The buttons below drive preferences; the secure
    // one is shown beside it so the split is visible rather than described.
    final StorageService storage = ref.watch(preferencesStorageProvider);
    final StorageService secure = ref.watch(secureStorageProvider);
    final LoggerService logger = ref.watch(loggerServiceProvider);
    final AsyncValue<bool> onboarding = ref.watch(onboardingStateProvider);

    return ShowcasePage(
      title: 'Storage & providers',
      sections: [
        Section(
          title: 'Core startup',
          api: 'CoreInitializer · CoreConfig',
          children: [
            Readout('isInitialized', '${CoreInitializer.isInitialized}'),
            Readout('shared logger', CoreInitializer.logger.runtimeType.name),
            Readout('default env file', const CoreConfig(appName: appName).envFile),
            Gap.hXs,
            Text(
              'main() calls CoreInitializer.quickStart, which sets up the '
              'binding and loads .env — a missing file is tolerated.',
              style: AppTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        Section(
          title: 'Two stores, different costs',
          api: 'preferencesStorageProvider · secureStorageProvider',
          children: [
            Readout('preferences', storage.runtimeType.name),
            Readout('secure', secure.runtimeType.name),
            Gap.hXs,
            Text(
              'Settings go in preferences: an on-device file, read once into '
              'memory. Tokens go in the keystore, which is slower and can be '
              'unavailable before the device is first unlocked. Until 6.0.0 '
              'both went through the keystore, so every app paid that price '
              'for its theme.',
              style: AppTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        Section(
          title: 'Key-value storage, for real',
          api: 'StorageService — driving the preferences store',
          children: [
            Gap.hSm,
            CustomTextField(
              controller: _keyController,
              label: 'Key',
              prefixIcon: Icons.key,
            ),
            Gap.hSm,
            CustomTextField(
              controller: _valueController,
              label: 'Value',
              prefixIcon: Icons.data_object,
            ),
            Gap.hSm,
            CustomButton(
              text: 'write',
              size: ButtonSize.small,
              onPressed: () => _run('write', () async {
                await storage.write(
                  key: _keyController.text,
                  value: _valueController.text,
                );
                return 'ok';
              }),
            ),
            Gap.hXs,
            CustomButton(
              text: 'read',
              size: ButtonSize.small,
              type: ButtonType.secondary,
              onPressed: () =>
                  _run('read', () => storage.read(key: _keyController.text)),
            ),
            Gap.hXs,
            CustomButton(
              text: 'containsKey',
              size: ButtonSize.small,
              type: ButtonType.outlined,
              onPressed: () => _run(
                'containsKey',
                () async =>
                    '${await storage.containsKey(key: _keyController.text)}',
              ),
            ),
            Gap.hXs,
            CustomButton(
              text: 'delete',
              size: ButtonSize.small,
              type: ButtonType.outlined,
              onPressed: () => _run('delete', () async {
                await storage.delete(key: _keyController.text);
                return 'ok';
              }),
            ),
            Gap.hXs,
            CustomButton(
              text: 'clearAll',
              size: ButtonSize.small,
              type: ButtonType.danger,
              // Wipes the theme mode and onboarding flag too — they are
              // preferences as well.
              onPressed: () => _run('clearAll', () async {
                await storage.clearAll();
                return 'ok';
              }),
            ),
            Gap.hSm,
            Readout('result', _result),
          ],
        ),

        const Section(
          title: 'The keys the package owns',
          api: 'StorageConstants',
          children: [
            Readout('accessToken', StorageConstants.accessToken),
            Readout('refreshToken', StorageConstants.refreshToken),
            Readout('themeMode', StorageConstants.themeMode),
            Readout('onboardingSeen', StorageConstants.onboardingSeen),
          ],
        ),

        Section(
          title: 'Onboarding flag',
          api: 'onboardingStateProvider · markAsSeen / reset',
          children: [
            Readout(
              'state',
              onboarding.when(
                data: (seen) => 'seen: $seen',
                loading: () => 'loading…',
                error: (e, _) => 'error: $e',
              ),
            ),
            Gap.hSm,
            CustomButton(
              text: 'markAsSeen()',
              size: ButtonSize.small,
              onPressed: () =>
                  ref.read(onboardingStateProvider.notifier).markAsSeen(),
            ),
            Gap.hXs,
            CustomButton(
              text: 'reset()',
              size: ButtonSize.small,
              type: ButtonType.outlined,
              onPressed: () =>
                  ref.read(onboardingStateProvider.notifier).reset(),
            ),
          ],
        ),

        Section(
          title: 'Logging',
          api: 'loggerServiceProvider · LoggerService',
          children: [
            Text(
              'Output goes to the console. In release builds the filter drops '
              'everything below warning.',
              style: AppTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.hSm,
            Wrap(
              spacing: AppSpacings.wXs,
              runSpacing: AppSpacings.hXs,
              children: [
                for (final (label, call) in <(String, void Function())>[
                  ('d', () => logger.d('debug line', tag: 'Showcase')),
                  ('i', () => logger.i('info line', tag: 'Showcase')),
                  ('w', () => logger.w('warning line', tag: 'Showcase')),
                  (
                    'e',
                    () => logger.e(
                      'error line',
                      error: const CacheException(message: 'demo'),
                      tag: 'Showcase',
                    ),
                  ),
                  ('fatal', () => logger.fatal('fatal line', tag: 'Showcase')),
                  (
                    'logRequest',
                    () => logger.logRequest(
                      method: 'GET',
                      url: 'https://example.com/items',
                      headers: const {'accept': 'application/json'},
                    ),
                  ),
                  (
                    'logResponse',
                    () => logger.logResponse(
                      statusCode: 200,
                      url: 'https://example.com/items',
                      data: const {'count': 2},
                    ),
                  ),
                  (
                    'logError',
                    () => logger.logError(
                      url: 'https://example.com/items',
                      error: 'connection refused',
                    ),
                  ),
                ])
                  ActionChip(label: Text(label), onPressed: call),
              ],
            ),
            Gap.hSm,
            // maskSensitive is the one logger call with a visible result.
            Readout(
              'maskSensitive',
              logger.maskSensitive('sk_live_4242424242'),
            ),
            Readout(
              'maskSensitive("ab")',
              logger.maskSensitive('ab'),
            ),
          ],
        ),
      ],
    );
  }
}

extension on Type {
  /// The runtime type as a plain string, for readouts.
  String get name => toString();
}
