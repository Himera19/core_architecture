// lib/src/dio/dio_providers.dart

import 'package:core_architecture/core_architecture.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  return DioCrudClient(dio: dio, logger: logger);
}

// ==================== Auth ====================

/// Whether the user is signed in, for apps whose REST API issues the tokens.
///
/// The Dio counterpart of `SupabaseAuth`: it starts from the stored access
/// token and follows [DioService.sessionChanges], so a session that ends
/// because a refresh failed flips it to `false` without any call from the app.
/// Endpoints and token fields come from [DioAuthConfig].
@Riverpod(keepAlive: true)
class DioAuth extends _$DioAuth {
  @override
  Future<bool> build() {
    final dio = ref.watch(dioServiceProvider);

    final subscription = dio.sessionChanges.listen(
      (signedIn) => state = AsyncValue.data(signedIn),
    );
    ref.onDispose(subscription.cancel);

    return dio.hasSession();
  }

  /// Signs in and returns the response body. Throws a [Failure].
  Future<Map<String, dynamic>> signIn({
    required String identifier,
    required String password,
  }) {
    return ref
        .read(dioServiceProvider)
        .signIn(identifier: identifier, password: password);
  }

  /// Signs up and returns the response body. The user is signed in only when
  /// the response carries tokens. Throws a [Failure].
  Future<Map<String, dynamic>> signUp({
    required String identifier,
    required String password,
    Map<String, dynamic> data = const {},
  }) {
    return ref
        .read(dioServiceProvider)
        .signUp(identifier: identifier, password: password, data: data);
  }

  Future<void> signOut() => ref.read(dioServiceProvider).signOut();

  Future<void> requestPasswordReset(String identifier) =>
      ref.read(dioServiceProvider).requestPasswordReset(identifier);
}
