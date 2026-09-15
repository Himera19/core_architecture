import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'logging/logger_service.dart';
import '../services/storage_service.dart';
import '../services/secure_storage_service.dart';

part 'core_providers.g.dart';

// ==================== Core Service Providers ====================

@riverpod
LoggerService loggerService(Ref ref) {
  return LoggerService();
}

@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) {
  return SecureStorageService();
}
