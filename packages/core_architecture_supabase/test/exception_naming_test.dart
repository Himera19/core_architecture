// Regression guard for exception-type name collisions.
//
// core_architecture used to export `AuthException` and `StorageException`,
// which shadowed the Supabase SDK's same-named types. `supabase_service.dart`
// then caught the *wrong* type: the clauses compiled fine but never matched
// anything the SDK threw, so every auth and storage error fell through to the
// generic handler. It also exported `TimeoutException`, silently shadowing the
// one `Future.timeout()` throws.
//
// The fix was to rename core's types — AuthenticationException,
// LocalStorageException, RequestTimeoutException — so the SDK and dart:async
// names stay unambiguous everywhere. These tests fail if the old names return.

import 'dart:async';

import 'package:core_architecture/core_architecture.dart' as core;
import 'package:core_architecture_supabase/core_architecture_supabase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

void main() {
  group('the package barrel resolves SDK exception names to the SDK', () {
    test('AuthException is the SDK type, not core\'s', () {
      const error = AuthException('Invalid login credentials');

      expect(error, isA<sb.AuthException>());
      expect(error, isNot(isA<core.AppException>()));
    });

    test('StorageException is the SDK type, not core\'s', () {
      const error = StorageException('Object not found');

      expect(error, isA<sb.StorageException>());
      expect(error, isNot(isA<core.AppException>()));
    });

    test('catching the unprefixed name matches what the SDK throws', () {
      var caughtAuth = false;
      try {
        throw const sb.AuthException('Invalid login credentials');
      } on AuthException {
        caughtAuth = true;
      }
      expect(
        caughtAuth,
        isTrue,
        reason: 'this silently failed in v1.x — the bug this guards',
      );

      var caughtStorage = false;
      try {
        throw const sb.StorageException('Object not found');
      } on StorageException {
        caughtStorage = true;
      }
      expect(caughtStorage, isTrue);
    });
  });

  group("core's own exception types do not collide", () {
    test('they extend AppException under collision-free names', () {
      const auth = core.AuthenticationException(message: 'Session expired');
      const storage = core.LocalStorageException(message: 'Keystore locked');
      const timeout = core.RequestTimeoutException(message: 'Took too long');

      expect(auth, isA<core.AppException>());
      expect(storage, isA<core.AppException>());
      expect(timeout, isA<core.AppException>());
    });

    test('dart:async TimeoutException is left alone', () {
      // This file imports dart:async *and* both package barrels unprefixed.
      // If core re-introduced its own TimeoutException, this would either fail
      // to compile (ambiguous import) or silently bind to the wrong type.
      var caught = false;
      try {
        throw TimeoutException('from Future.timeout');
      } on core.RequestTimeoutException {
        fail('core type must not intercept dart:async TimeoutException');
      } on TimeoutException catch (e) {
        caught = true;
        expect(e, isNot(isA<core.AppException>()));
      }
      expect(caught, isTrue);
    });

    test('a real Future.timeout is catchable as TimeoutException', () async {
      await expectLater(
        Completer<void>().future.timeout(const Duration(milliseconds: 1)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
