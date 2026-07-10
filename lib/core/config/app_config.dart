import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuração de ambiente carregada de `.env` (não commitar secrets).
class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
    this.syncDebugUploadDelaySeconds = 0,
    this.tusUploadStallTimeoutSeconds = 25,
    this.syncDrainCycleTimeoutMinutes = 30,
    this.syncInitialContactTimeoutSeconds = 10,
    this.syncInitialContactRetryBackoffSeconds = 3,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;

  /// Atraso artificial antes do upload TUS (só dev). 0 = desligado.
  final int syncDebugUploadDelaySeconds;

  /// Sem bytes/progresso TUS por este intervalo → aborta upload (ENI-105).
  final int tusUploadStallTimeoutSeconds;

  /// Teto de duração de um ciclo de drain de sync (ENI-105).
  final int syncDrainCycleTimeoutMinutes;

  /// Timeout do primeiro contato HTTP (GET /me, POST /occurrences/sync) — ENI-105.
  final int syncInitialContactTimeoutSeconds;

  /// Backoff entre tentativas de primeiro contato — ENI-105.
  final int syncInitialContactRetryBackoffSeconds;

  static Future<AppConfig> load({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName);
    } on Object {
      final fallback = switch (fileName) {
        '.env.dev' => '.env.dev.example',
        '.env.prod' => '.env.prod.example',
        _ => '.env.example',
      };
      await dotenv.load(fileName: fallback);
    }

    final supabaseUrl = _require('SUPABASE_URL');
    final supabaseAnonKey = _require('SUPABASE_ANON_KEY');
    final apiBaseUrl = _require('API_BASE_URL').replaceAll(RegExp(r'/+$'), '');

    return AppConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      apiBaseUrl: apiBaseUrl,
      syncDebugUploadDelaySeconds: _optionalInt('SYNC_DEBUG_UPLOAD_DELAY_SECONDS'),
      tusUploadStallTimeoutSeconds:
          _optionalIntWithDefault('TUS_UPLOAD_STALL_TIMEOUT_SECONDS', 25),
      syncDrainCycleTimeoutMinutes:
          _optionalIntWithDefault('SYNC_DRAIN_CYCLE_TIMEOUT_MINUTES', 30),
      syncInitialContactTimeoutSeconds:
          _optionalIntWithDefault('SYNC_INITIAL_CONTACT_TIMEOUT_SECONDS', 10),
      syncInitialContactRetryBackoffSeconds: _optionalIntWithDefault(
        'SYNC_INITIAL_CONTACT_RETRY_BACKOFF_SECONDS',
        3,
      ),
    );
  }

  static AppConfig fromMap(Map<String, String> values) {
    return AppConfig(
      supabaseUrl: _requireFromMap(values, 'SUPABASE_URL'),
      supabaseAnonKey: _requireFromMap(values, 'SUPABASE_ANON_KEY'),
      apiBaseUrl:
          _requireFromMap(values, 'API_BASE_URL').replaceAll(RegExp(r'/+$'), ''),
      syncDebugUploadDelaySeconds:
          _optionalIntFromMap(values, 'SYNC_DEBUG_UPLOAD_DELAY_SECONDS'),
      tusUploadStallTimeoutSeconds: _optionalIntWithDefaultFromMap(
        values,
        'TUS_UPLOAD_STALL_TIMEOUT_SECONDS',
        25,
      ),
      syncDrainCycleTimeoutMinutes: _optionalIntWithDefaultFromMap(
        values,
        'SYNC_DRAIN_CYCLE_TIMEOUT_MINUTES',
        30,
      ),
      syncInitialContactTimeoutSeconds: _optionalIntWithDefaultFromMap(
        values,
        'SYNC_INITIAL_CONTACT_TIMEOUT_SECONDS',
        10,
      ),
      syncInitialContactRetryBackoffSeconds: _optionalIntWithDefaultFromMap(
        values,
        'SYNC_INITIAL_CONTACT_RETRY_BACKOFF_SECONDS',
        3,
      ),
    );
  }

  static int _optionalInt(String key) =>
      _optionalIntFromMap(dotenv.env, key);

  static int _optionalIntWithDefault(String key, int defaultValue) =>
      _optionalIntWithDefaultFromMap(dotenv.env, key, defaultValue);

  static int _optionalIntFromMap(Map<String, String?> values, String key) {
    final raw = values[key]?.trim();
    if (raw == null || raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }

  static int _optionalIntWithDefaultFromMap(
    Map<String, String?> values,
    String key,
    int defaultValue,
  ) {
    final raw = values[key]?.trim();
    if (raw == null || raw.isEmpty) return defaultValue;
    return int.tryParse(raw) ?? defaultValue;
  }

  static String _require(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Variável de ambiente obrigatória ausente: $key');
    }
    return value;
  }

  static String _requireFromMap(Map<String, String> values, String key) {
    final value = values[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Variável de ambiente obrigatória ausente: $key');
    }
    return value;
  }
}
