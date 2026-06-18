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
}
