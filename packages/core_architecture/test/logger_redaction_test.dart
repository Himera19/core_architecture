import 'package:core_architecture/core_architecture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// Collects every printed line, so a test can search what reached the console.
class _Capture extends LogOutput {
  final List<String> lines = [];

  String get text => lines.join('\n');

  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  final logger = LoggerService();

  group('isSensitiveKey', () {
    test('matches secret-looking keys in any case or separator style', () {
      for (final key in [
        'password',
        'newPassword',
        'access_token',
        'refreshToken',
        'Authorization',
        'X-Api-Key',
        'api_key',
        'Set-Cookie',
        'client_secret',
        'otp',
        'PIN',
      ]) {
        expect(LoggerService.isSensitiveKey(key), isTrue, reason: key);
      }
    });

    test('leaves ordinary keys alone', () {
      for (final key in [
        'email',
        'name',
        'shipping',
        'footprint',
        'author',
        'id',
      ]) {
        expect(LoggerService.isSensitiveKey(key), isFalse, reason: key);
      }
    });

    test('app-specific keys can be added', () {
      expect(LoggerService.isSensitiveKey('iban'), isFalse);
      LoggerService.addSensitiveKeys(['IBAN']);
      expect(LoggerService.isSensitiveKey('customer_iban'), isTrue);
    });
  });

  group('redact', () {
    test('masks sensitive values at any depth and keeps the rest', () {
      final redacted = logger.redact({
        'email': 'ada@example.com',
        'password': 'hunter2',
        'data': {
          'user': {'id': 7, 'name': 'Ada'},
          'access_token': 'eyJhbGciOiJIUzI1NiJ9.payload.sig',
          'sessions': [
            {'refresh_token': 'r-0123456789abcdef'},
          ],
        },
      });

      expect(redacted, {
        'email': 'ada@example.com',
        'password': '****',
        'data': {
          'user': {'id': 7, 'name': 'Ada'},
          'access_token':
              '${'*' * ('eyJhbGciOiJIUzI1NiJ9.payload.sig'.length - 4)}.sig',
          'sessions': [
            {'refresh_token': '**************cdef'},
          ],
        },
      });
    });

    test('keeps the auth scheme and only the tail of the credential', () {
      final redacted =
          logger.redact({'Authorization': 'Bearer abcdefghijklmnop'}) as Map;
      expect(redacted['Authorization'], 'Bearer ************mnop');
    });

    test('never leaks a short secret, even partly', () {
      expect(logger.redact({'pin': '1234'}), {'pin': '****'});
      expect(logger.redact({'token': 42}), {'token': '****'});
    });

    test('decodes, redacts and re-encodes a JSON string body', () {
      expect(
        logger.redact('{"email":"a@b.co","password":"hunter2"}'),
        '{"email":"a@b.co","password":"****"}',
      );
    });

    test('leaves non-JSON strings and scalars untouched', () {
      expect(logger.redact('plain text'), 'plain text');
      expect(logger.redact('{not json'), '{not json');
      expect(logger.redact(42), 42);
      expect(logger.redact(null), isNull);
    });
  });

  group('redactUrl', () {
    test('masks sensitive query parameters', () {
      final url = logger.redactUrl(
        'https://api.test/verify?email=a%40b.co&token=abcdefghijklmnop',
      );
      expect(url, contains('email=a%40b.co'));
      expect(url, isNot(contains('abcdefghijklmnop')));
      expect(url, contains('mnop'));
    });

    test('returns a URL without secrets unchanged', () {
      const url = 'https://api.test/items?page=2&order_by=created_at';
      expect(logger.redactUrl(url), url);
    });
  });

  group('HTTP logging', () {
    test('a sign-in request and its response print no secret', () {
      final capture = _Capture();
      final log = LoggerService.withOutput(capture);

      log.logRequest(
        method: 'POST',
        url: 'https://api.test/auth/login?api_key=k-0123456789abcdef',
        headers: {'Authorization': 'Bearer old-access-token-value'},
        body: {'email': 'ada@example.com', 'password': 'correct horse battery'},
      );
      log.logResponse(
        statusCode: 200,
        url: 'https://api.test/auth/login',
        data: {
          'access_token': 'new-access-token-value',
          'refresh_token': 'new-refresh-token-value',
        },
      );

      for (final secret in [
        'k-0123456789abcdef',
        'old-access-token-value',
        'correct horse battery',
        'new-access-token-value',
        'new-refresh-token-value',
      ]) {
        expect(capture.text, isNot(contains(secret)), reason: secret);
      }
      expect(capture.text, contains('ada@example.com'));
      expect(capture.text, contains('Bearer'));
    });

    test('a long response is redacted, then truncated', () {
      final capture = _Capture();
      final log = LoggerService.withOutput(capture);

      log.logResponse(
        statusCode: 200,
        url: 'https://api.test/items',
        // The secret comes first, inside the 500 characters that survive the
        // cut — so only redaction can be what keeps it out.
        data: {
          'token': 'secret-token-up-front',
          'items': List.filled(300, 'x'),
        },
      );

      expect(capture.text, contains('(truncated)'));
      expect(capture.text, isNot(contains('secret-token-up-front')));
    });
  });
}
