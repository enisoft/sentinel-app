import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_key_value_store.dart';

/// Persiste a sessão Supabase em armazenamento seguro (Keystore no Android).
class SecureSupabaseLocalStorage extends LocalStorage {
  SecureSupabaseLocalStorage({
    required this.persistSessionKey,
    required SecureKeyValueStore store,
    this.legacySharedPrefsKey,
  }) : _store = store;

  final String persistSessionKey;
  final String? legacySharedPrefsKey;
  final SecureKeyValueStore _store;

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    WidgetsFlutterBinding.ensureInitialized();
    await _migrateFromSharedPreferencesIfNeeded();
    _initialized = true;
  }

  Future<void> _migrateFromSharedPreferencesIfNeeded() async {
    final legacyKey = legacySharedPrefsKey;
    if (legacyKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    final legacySession = prefs.getString(legacyKey);
    if (legacySession == null) return;

    final alreadyMigrated = await _store.containsKey(persistSessionKey);
    if (!alreadyMigrated) {
      await _store.write(persistSessionKey, legacySession);
    }
    await prefs.remove(legacyKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    await initialize();
    return _store.containsKey(persistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    await initialize();
    return _store.read(persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await initialize();
    await _store.delete(persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await initialize();
    await _store.write(persistSessionKey, persistSessionString);
  }
}
