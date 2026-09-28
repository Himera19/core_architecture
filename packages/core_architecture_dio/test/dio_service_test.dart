import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_architecture_dio/core_architecture_dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements StorageService {
  final Map<String, String> values = {};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async =>
      values[key] = value;

  @override
  Future<void> delete({required String key}) async => values.remove(key);

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<bool> containsKey({required String key}) async =>
      values.containsKey(key);
}

/// Answers every request with [respond] and records what was sent.
class _FakeApi implements HttpClientAdapter {
  _FakeApi(this.respond);

  final FutureOr<ResponseBody> Function(RequestOptions request) respond;
  final List<RequestOptions> requests = [];

  Iterable<String> get paths => requests.map((r) => r.path);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

String? _bearer(RequestOptions request) =>
    request.headers['Authorization'] as String?;

Future<(DioService, _MemoryStorage)> _init(
  _FakeApi api, {
  DioConfig config = const DioConfig(),
}) async {
  final storage = _MemoryStorage();
  await DioService.initialize(
    baseUrl: 'https://api.test',
    config: config,
    storage: storage,
    httpClientAdapter: api,
  );
  return (DioService.instance, storage);
}

void main() {
  test('config reaches the options and the token endpoints', () async {
    final api = _FakeApi(
      (r) => r.path == '/v1/sessions'
          ? _json(200, {
              'data': {'token': 'A1', 'refresh': 'R1'},
            })
          : _json(200, {}),
    );
    final (dio, storage) = await _init(
      api,
      config: const DioConfig(
        receiveTimeout: Duration(seconds: 5),
        headers: {'X-App': 'demo'},
        auth: DioAuthConfig(
          loginPath: '/v1/sessions',
          identifierField: 'username',
          accessTokenField: 'data.token',
          refreshTokenField: 'data.refresh',
          tokenType: 'Token',
        ),
      ),
    );
    final signedIn = expectLater(dio.sessionChanges, emits(true));

    await dio.signIn(identifier: 'ada', password: 'pw');
    await signedIn;
    await dio.get<void>('/me');

    expect(api.requests.first.data, {'username': 'ada', 'password': 'pw'});
    expect(storage.values[StorageConstants.accessToken], 'A1');
    expect(storage.values[StorageConstants.refreshToken], 'R1');
    expect(_bearer(api.requests.last), 'Token A1');
    expect(api.requests.last.headers['X-App'], 'demo');
    expect(api.requests.last.receiveTimeout, const Duration(seconds: 5));
  });

  test(
    'parallel 401s share one refresh and retry with the new token',
    () async {
      final api = _FakeApi((r) async {
        if (r.path == '/auth/refresh') {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return _json(200, {'access_token': 'new', 'refresh_token': 'R2'});
        }
        return _bearer(r) == 'Bearer new'
            ? _json(200, {'ok': true})
            : _json(401, {'message': 'expired'});
      });
      final (dio, storage) = await _init(api);
      storage.values
        ..[StorageConstants.accessToken] = 'old'
        ..[StorageConstants.refreshToken] = 'R1';

      final responses = await Future.wait([
        dio.get<Map<String, dynamic>>('/a'),
        dio.get<Map<String, dynamic>>('/b'),
      ]);

      expect(responses.map((r) => r.data), everyElement({'ok': true}));
      expect(api.paths.where((p) => p == '/auth/refresh'), hasLength(1));
      expect(api.requests.firstWhere((r) => r.path == '/auth/refresh').data, {
        'refresh_token': 'R1',
      });
      expect(storage.values[StorageConstants.refreshToken], 'R2');
    },
  );

  test(
    'a refresh that gets a 401 ends the session instead of looping',
    () async {
      final api = _FakeApi((r) => _json(401, {'message': 'nope'}));
      final (dio, storage) = await _init(api);
      storage.values
        ..[StorageConstants.accessToken] = 'old'
        ..[StorageConstants.refreshToken] = 'R1';
      final signedOut = expectLater(dio.sessionChanges, emits(false));

      final error = await dio
          .get<void>('/a')
          .then<Object?>((_) => null, onError: (Object e) => e);

      await signedOut;
      expect(error, isA<DioException>());
      expect((error! as DioException).error, isA<UnauthorizedFailure>());
      expect(api.paths, ['/a', '/auth/refresh']);
      expect(storage.values, isEmpty);
    },
  );

  test(
    'a retried request that still gets a 401 is not refreshed again',
    () async {
      final api = _FakeApi(
        (r) => r.path == '/auth/refresh'
            ? _json(200, {'access_token': 'new'})
            : _json(401, {}),
      );
      final (dio, storage) = await _init(api);
      storage.values
        ..[StorageConstants.accessToken] = 'old'
        ..[StorageConstants.refreshToken] = 'R1';

      await expectLater(dio.get<void>('/a'), throwsA(isA<DioException>()));

      expect(api.paths, ['/a', '/auth/refresh', '/a']);
      expect(await dio.hasSession(), isFalse);
    },
  );

  test(
    'a 401 without a stored token is not treated as an expired session',
    () async {
      final api = _FakeApi((r) => _json(401, {}));
      final (dio, _) = await _init(api);

      await expectLater(dio.get<void>('/a'), throwsA(isA<DioException>()));
      expect(api.paths, ['/a']);
    },
  );

  test('a plain-text error body does not crash the error mapping', () async {
    final api = _FakeApi((r) => ResponseBody.fromString('Bad Gateway', 400));
    final (dio, _) = await _init(api);

    final error = await dio
        .get<void>('/a')
        .then<Object?>((_) => null, onError: (Object e) => e);

    final failure = (error! as DioException).error;
    expect(failure, isA<NetworkFailure>());
    expect((failure! as Failure).message, 'Request failed');
  });

  test('rejected credentials throw the Failure, not a DioException', () async {
    final api = _FakeApi((r) => _json(401, {'message': 'Wrong password'}));
    final (dio, _) = await _init(api);

    await expectLater(
      dio.signIn(identifier: 'ada', password: 'x'),
      throwsA(
        isA<UnauthorizedFailure>().having(
          (f) => f.message,
          'message',
          'Wrong password',
        ),
      ),
    );
  });

  test('dioAuthProvider follows the session', () async {
    final api = _FakeApi(
      (r) => r.path == '/auth/login'
          ? _json(200, {'access_token': 'A1'})
          : _json(200, {}),
    );
    final (dio, _) = await _init(api);
    final container = ProviderContainer(
      overrides: [dioServiceProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);
    container.listen(dioAuthProvider, (_, _) {});

    expect(await container.read(dioAuthProvider.future), isFalse);

    await container
        .read(dioAuthProvider.notifier)
        .signIn(identifier: 'ada', password: 'pw');
    await pumpEventQueue();
    expect(container.read(dioAuthProvider).value, isTrue);

    await container.read(dioAuthProvider.notifier).signOut();
    await pumpEventQueue();
    expect(container.read(dioAuthProvider).value, isFalse);
  });
}
