import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/auth/silent_refresh_result.dart';
import 'package:sentinel_app/core/bootstrap/bootstrap_messages.dart';
import 'package:sentinel_app/data/gateways/supabase_auth_gateway.dart';

void main() {
  test('_isRefreshNetworkFailure detects timeout and network errors', () {
    expect(
      SupabaseAuthGateway.isRefreshNetworkFailureForTest(
        TimeoutException('refresh'),
      ),
      isTrue,
    );
    expect(
      SupabaseAuthGateway.isRefreshNetworkFailureForTest(
        Exception('SocketException: failed host lookup'),
      ),
      isTrue,
    );
    expect(
      SupabaseAuthGateway.isRefreshNetworkFailureForTest(
        Exception('invalid_grant'),
      ),
      isFalse,
    );
  });
}
