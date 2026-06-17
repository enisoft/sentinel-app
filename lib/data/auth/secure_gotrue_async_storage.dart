import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_key_value_store.dart';

/// Armazena verificadores PKCE em secure storage em vez de SharedPreferences.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  SecureGotrueAsyncStorage({required SecureKeyValueStore store}) : _store = store;

  final SecureKeyValueStore _store;

  static String _pkceKey(String key) => 'pkce-$key';

  @override
  Future<String?> getItem({required String key}) =>
      _store.read(_pkceKey(key));

  @override
  Future<void> removeItem({required String key}) =>
      _store.delete(_pkceKey(key));

  @override
  Future<void> setItem({required String key, required String value}) =>
      _store.write(_pkceKey(key), value);
}
