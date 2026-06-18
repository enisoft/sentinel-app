import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuração de ambiente carregada de `.env` (não commitar secrets).
class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
    this.syncDebugUploadDelaySeconds = 0,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;

  /// Atraso artificial antes do upload TUS (só dev). 0 = desligado.
  final int syncDebugUploadDelaySeconds;

  static Future<AppConfig> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } on Object {
      await dotenv.load(fileName: '.env.example');
    }

    final supabaseUrl = _require('SUPABASE_URL');
    final supabaseAnonKey = _require('SUPABASE_ANON_KEY');
    final apiBaseUrl = _require('API_BASE_URL').replaceAll(RegExp(r'/+$'), '');

    return AppConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      apiBaseUrl: apiBaseUrl,
      syncDebugUploadDelaySeconds: _optionalInt('SYNC_DEBUG_UPLOAD_DELAY_SECONDS'),
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
    );
  }

  static int _optionalInt(String key) =>
      _optionalIntFromMap(dotenv.env, key);

  static int _optionalIntFromMap(Map<String, String?> values, String key) {
    final raw = values[key]?.trim();
    if (raw == null || raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
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
