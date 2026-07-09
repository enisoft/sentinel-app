import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sentinel_app/core/network/initial_contact_retry.dart';
import 'package:sentinel_app/data/remote/api_exception.dart';

void main() {
  test('isInitialContactRetryable covers network failures', () {
    expect(isInitialContactRetryable(const SocketException('down')), isTrue);
    expect(
      isInitialContactRetryable(http.ClientException('refused')),
      isTrue,
    );
    expect(
      isInitialContactRetryable(
        ApiException(408, 'timeout', isNetworkError: true),
      ),
      isTrue,
    );
    expect(
      isInitialContactRetryable(ApiException(401, 'unauthorized')),
      isFalse,
    );
    expect(
      isInitialContactRetryable(ApiException(422, 'validation')),
      isFalse,
    );
  });

  test('withInitialContactRetry succeeds on first attempt', () async {
    var attempts = 0;

    final value = await withInitialContactRetry(
      () async {
        attempts++;
        return 'ok';
      },
      backoff: const Duration(milliseconds: 10),
    );

    expect(value, 'ok');
    expect(attempts, 1);
  });

  test('withInitialContactRetry retries once after network failure', () async {
    var attempts = 0;

    final value = await withInitialContactRetry(
      () async {
        attempts++;
        if (attempts == 1) {
          throw const SocketException('down');
        }
        return 'ok';
      },
      backoff: const Duration(milliseconds: 20),
    );

    expect(value, 'ok');
    expect(attempts, 2);
  });

  test('withInitialContactRetry rethrows after second network failure', () async {
    var attempts = 0;

    await expectLater(
      withInitialContactRetry(
        () async {
          attempts++;
          throw const SocketException('down');
        },
        backoff: const Duration(milliseconds: 10),
      ),
      throwsA(isA<SocketException>()),
    );

    expect(attempts, 2);
  });

  test('withInitialContactRetry does not retry non-network errors', () async {
    var attempts = 0;

    await expectLater(
      withInitialContactRetry(
        () async {
          attempts++;
          throw ApiException(422, 'validation');
        },
        backoff: const Duration(milliseconds: 10),
      ),
      throwsA(isA<ApiException>()),
    );

    expect(attempts, 1);
  });
}
