import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/config/app_config.dart';

void main() {
  test('fromMap defaults sync debug upload delay to zero', () {
    final config = AppConfig.fromMap({
      'SUPABASE_URL': 'http://localhost:54321',
      'SUPABASE_ANON_KEY': 'key',
      'API_BASE_URL': 'http://localhost:8000/api/v1',
    });

    expect(config.syncDebugUploadDelaySeconds, 0);
  });

  test('fromMap parses SYNC_DEBUG_UPLOAD_DELAY_SECONDS', () {
    final config = AppConfig.fromMap({
      'SUPABASE_URL': 'http://localhost:54321',
      'SUPABASE_ANON_KEY': 'key',
      'API_BASE_URL': 'http://localhost:8000/api/v1',
      'SYNC_DEBUG_UPLOAD_DELAY_SECONDS': '8',
    });

    expect(config.syncDebugUploadDelaySeconds, 8);
  });

  test('fromMap treats invalid delay as zero', () {
    final config = AppConfig.fromMap({
      'SUPABASE_URL': 'http://localhost:54321',
      'SUPABASE_ANON_KEY': 'key',
      'API_BASE_URL': 'http://localhost:8000/api/v1',
      'SYNC_DEBUG_UPLOAD_DELAY_SECONDS': 'nope',
    });

    expect(config.syncDebugUploadDelaySeconds, 0);
  });

  test('fromMap defaults TUS stall timeout to 25 seconds', () {
    final config = AppConfig.fromMap({
      'SUPABASE_URL': 'http://localhost:54321',
      'SUPABASE_ANON_KEY': 'key',
      'API_BASE_URL': 'http://localhost:8000/api/v1',
    });

    expect(config.tusUploadStallTimeoutSeconds, 25);
    expect(config.syncDrainCycleTimeoutMinutes, 30);
    expect(config.syncInitialContactTimeoutSeconds, 10);
    expect(config.syncInitialContactRetryBackoffSeconds, 3);
  });

  test('fromMap parses ENI-105 timeout env vars', () {
    final config = AppConfig.fromMap({
      'SUPABASE_URL': 'http://localhost:54321',
      'SUPABASE_ANON_KEY': 'key',
      'API_BASE_URL': 'http://localhost:8000/api/v1',
      'TUS_UPLOAD_STALL_TIMEOUT_SECONDS': '40',
      'SYNC_DRAIN_CYCLE_TIMEOUT_MINUTES': '15',
      'SYNC_INITIAL_CONTACT_TIMEOUT_SECONDS': '8',
      'SYNC_INITIAL_CONTACT_RETRY_BACKOFF_SECONDS': '2',
    });

    expect(config.tusUploadStallTimeoutSeconds, 40);
    expect(config.syncDrainCycleTimeoutMinutes, 15);
    expect(config.syncInitialContactTimeoutSeconds, 8);
    expect(config.syncInitialContactRetryBackoffSeconds, 2);
  });
}
