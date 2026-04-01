import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/storage_constants.dart';
import '../core/core_providers.dart';
import '../core/logging/logger_service.dart';
import '../services/storage_service.dart';

part 'onboarding_provider.g.dart';

@Riverpod(keepAlive: true)
class OnboardingState extends _$OnboardingState {
  static const String _storageKey = StorageConstants.onboardingSeen;
  late final StorageService _storage;
  late final LoggerService _logger;

  @override
  FutureOr<bool> build() async {
    _storage = ref.watch(storageServiceProvider);
    _logger = ref.watch(loggerServiceProvider);

    // Check if onboarding was already seen
    final seen = await _storage.read(key: _storageKey);
    _logger.i('Onboarding seen: ${seen ?? "false"}', tag: 'Onboarding');
    return seen == 'true';
  }

  /// Mark onboarding as seen
  Future<void> markAsSeen() async {
    await _storage.write(key: _storageKey, value: 'true');
    state = const AsyncValue.data(true);
    _logger.i('Onboarding marked as seen', tag: 'Onboarding');
  }

  /// Reset onboarding (for testing)
  Future<void> reset() async {
    await _storage.delete(key: _storageKey);
    state = const AsyncValue.data(false);
    _logger.i('Onboarding reset', tag: 'Onboarding');
  }
}
