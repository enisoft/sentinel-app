import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentinel_app/data/auth/secure_gotrue_async_storage.dart';
import 'package:sentinel_app/data/auth/secure_key_value_store.dart';
import 'package:sentinel_app/data/auth/secure_supabase_local_storage.dart';
import 'package:sentinel_app/data/auth/supabase_session_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureSupabaseLocalStorage', () {
    late InMemorySecureKeyValueStore store;
    late SecureSupabaseLocalStorage storage;

    setUp(() {
      store = InMemorySecureKeyValueStore();
      storage = SecureSupabaseLocalStorage(
        persistSessionKey: supabaseSecureSessionKey,
        store: store,
      );
    });

    test('persistSession writes and accessToken reads', () async {
      const session = '{"access_token":"jwt","refresh_token":"rt"}';

      await storage.persistSession(session);

      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), session);
    });

    test('removePersistedSession deletes session', () async {
      await storage.persistSession('{"access_token":"jwt"}');
      await storage.removePersistedSession();

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    });

    test('migrates legacy SharedPreferences session and clears old key', () async {
      const legacyKey = 'sb-localhost-auth-token';
      const legacySession = '{"access_token":"legacy-jwt"}';

      SharedPreferences.setMockInitialValues({legacyKey: legacySession});

      final migratingStorage = SecureSupabaseLocalStorage(
        persistSessionKey: supabaseSecureSessionKey,
        store: store,
        legacySharedPrefsKey: legacyKey,
      );

      await migratingStorage.initialize();

      expect(await migratingStorage.accessToken(), legacySession);
      expect(
        SharedPreferences.getInstance().then((p) => p.containsKey(legacyKey)),
        completion(isFalse),
      );
      expect(await store.read(supabaseSecureSessionKey), legacySession);
    });

    test('migration skips when secure storage already has session', () async {
      const legacyKey = 'sb-localhost-auth-token';
      const secureSession = '{"access_token":"secure-jwt"}';
      const legacySession = '{"access_token":"legacy-jwt"}';

      await store.write(supabaseSecureSessionKey, secureSession);
      SharedPreferences.setMockInitialValues({legacyKey: legacySession});

      final migratingStorage = SecureSupabaseLocalStorage(
        persistSessionKey: supabaseSecureSessionKey,
        store: store,
        legacySharedPrefsKey: legacyKey,
      );

      await migratingStorage.initialize();

      expect(await migratingStorage.accessToken(), secureSession);
      expect(
        SharedPreferences.getInstance().then((p) => p.containsKey(legacyKey)),
        completion(isFalse),
      );
    });
  });

  group('SecureGotrueAsyncStorage', () {
    test('setItem, getItem and removeItem', () async {
      final store = InMemorySecureKeyValueStore();
      final pkce = SecureGotrueAsyncStorage(store: store);

      await pkce.setItem(key: 'code-verifier', value: 'abc123');
      expect(await pkce.getItem(key: 'code-verifier'), 'abc123');

      await pkce.removeItem(key: 'code-verifier');
      expect(await pkce.getItem(key: 'code-verifier'), isNull);
    });
  });
}

/// Fake em memória — testes não dependem de Keystore nem IO real.
class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);
}
