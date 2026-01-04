// lib/src/backends/dio/dio_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/core_providers.dart';
import 'dio_crud_client.dart';
import 'dio_service.dart';

part 'dio_providers.g.dart';

// ==================== Service Providers ====================

@Riverpod(keepAlive: true)
DioService dioService(Ref ref) {
  // This assumes DioService.initialize() was called in main.dart
  return DioService.instance;
}

// ==================== Backend Client Providers ====================

@Riverpod(keepAlive: true)
DioCrudClient dioCrudClient(Ref ref) {
  final dio = ref.watch(dioServiceProvider);
  final logger = ref.watch(loggerServiceProvider);

  return DioCrudClient(
    dio: dio,
    logger: logger,
  );
}
