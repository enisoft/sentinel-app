import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/network/network_reachability.dart';
import '../data/auth/secure_gotrue_async_storage.dart';
import '../data/auth/secure_key_value_store.dart';
import '../data/auth/secure_supabase_local_storage.dart';
import '../data/auth/supabase_session_keys.dart';
import '../data/device/crypto_hash_service.dart';
import '../data/device/device_camera_source.dart';
import '../data/device/geolocator_location_source.dart';
import '../data/fakes/fake_camera_source.dart';
import '../data/fakes/fake_hash_service.dart';
import '../data/fakes/fake_location_source.dart';
import '../data/settings/capture_quality_settings.dart';
import '../data/gateways/supabase_auth_gateway.dart';
import '../data/gateways/sync_gateway_http.dart';
import '../data/local/app_database.dart';
import '../data/remote/api_client.dart';
import '../data/remote/tus_media_uploader.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/check_in_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/occurrence_repository.dart';
import '../data/repositories/operator_profile_repository.dart';
import '../data/repositories/sync_queue_repository.dart';
import '../data/services/bootstrap_service.dart';
import '../data/services/capture_occurrence_service.dart';
import '../data/services/catalog_sync_service.dart';
import '../data/services/occurrence_sync_coordinator.dart';
import '../data/services/occurrence_sync_foreground_runner.dart';
import '../data/services/occurrence_sync_service.dart';
import '../platform/sync_foreground_platform.dart';
import '../domain/gateways/auth_gateway.dart';
import '../domain/gateways/media_uploader.dart';
import '../domain/gateways/sync_gateway.dart';
import '../domain/services/camera_source.dart';
import '../domain/services/hash_service.dart';
import '../domain/services/location_source.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) {
    return;
  }

  final config = await AppConfig.load();

  final secureStore = FlutterSecureKeyValueStore();
  final legacyKey = legacySharedPrefsSessionKey(config.supabaseUrl);

  getIt.registerSingleton<SecureKeyValueStore>(secureStore);
  getIt.registerLazySingleton<NetworkReachability>(
    () => DnsNetworkReachability(),
  );

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSupabaseLocalStorage(
        persistSessionKey: supabaseSecureSessionKey,
        store: secureStore,
        legacySharedPrefsKey: legacyKey,
      ),
      pkceAsyncStorage: SecureGotrueAsyncStorage(store: secureStore),
    ),
  );

  getIt.registerSingleton<AppConfig>(config);

  await _registerCaptureQualitySettings();

  final db = await AppDatabase.openDefault();
  await _registerCore(db, config);
  _registerCaptureProduction();
}

Future<void> configureDependenciesForTesting(
  AppDatabase db, {
  AppConfig? config,
  AuthGateway? authGateway,
  ApiClient? apiClient,
  SyncGateway? syncGateway,
  MediaUploader? mediaUploader,
  CameraSource? cameraSource,
  LocationSource? locationSource,
  HashService? hashService,
  OccurrenceSyncCoordinator? occurrenceSyncCoordinator,
  SyncForegroundPlatform? syncForegroundPlatform,
  OccurrenceSyncForegroundRunner? occurrenceSyncForegroundRunner,
}) async {
  await getIt.reset();
  SharedPreferences.setMockInitialValues({});

  final testConfig = config ??
      AppConfig.fromMap({
        'SUPABASE_URL': 'http://localhost:54321',
        'SUPABASE_ANON_KEY': 'test-anon-key',
        'API_BASE_URL': 'http://localhost:8000/api/v1',
      });

  getIt.registerSingleton<AppConfig>(testConfig);

  await _registerCaptureQualitySettings();

  final auth = authGateway ?? _UnimplementedAuthGateway();
  getIt.registerSingleton<AuthGateway>(auth);

  await _registerCore(
    db,
    testConfig,
    apiClient: apiClient,
    syncGateway: syncGateway,
    mediaUploader: mediaUploader,
    occurrenceSyncCoordinator: occurrenceSyncCoordinator,
    syncForegroundPlatform: syncForegroundPlatform,
    occurrenceSyncForegroundRunner: occurrenceSyncForegroundRunner,
  );

  _registerCaptureServices(
    cameraSource: cameraSource ?? FakeCameraSource(),
    locationSource: locationSource ?? FakeLocationSource(),
    hashService: hashService ?? FakeHashService(),
  );
}

Future<void> _registerCore(
  AppDatabase db,
  AppConfig config, {
  ApiClient? apiClient,
  SyncGateway? syncGateway,
  MediaUploader? mediaUploader,
  OccurrenceSyncCoordinator? occurrenceSyncCoordinator,
  SyncForegroundPlatform? syncForegroundPlatform,
  OccurrenceSyncForegroundRunner? occurrenceSyncForegroundRunner,
}) async {
  getIt.registerSingleton<AppDatabase>(db);
  getIt.registerLazySingleton(() => OccurrenceRepository(getIt()));
  getIt.registerLazySingleton(() => CheckInRepository(getIt()));
  getIt.registerLazySingleton(() => SyncQueueRepository(getIt()));
  getIt.registerLazySingleton(() => CatalogRepository(getIt()));
  getIt.registerLazySingleton(() => MessageRepository(getIt(), getIt()));

  if (!getIt.isRegistered<AuthGateway>()) {
    getIt.registerLazySingleton<AuthGateway>(
      () => SupabaseAuthGateway(
        Supabase.instance.client,
        getIt<SecureKeyValueStore>(),
        networkReachability: getIt<NetworkReachability>(),
      ),
    );
  }

  getIt.registerLazySingleton<ApiClient>(
    () => apiClient ?? ApiClient(config: config, authGateway: getIt()),
  );

  getIt.registerLazySingleton<MediaUploader>(
    () =>
        mediaUploader ??
        TusMediaUploader(
          config: config,
          authGateway: getIt(),
          occurrenceRepository: getIt(),
        ),
  );

  getIt.registerLazySingleton<SyncGateway>(
    () =>
        syncGateway ??
        SyncGatewayHttp(
          apiClient: getIt(),
          occurrenceRepository: getIt(),
          mediaUploader: getIt(),
        ),
  );

  getIt.registerLazySingleton(
    () => OccurrenceSyncService(
      queueRepository: getIt(),
      occurrenceRepository: getIt(),
      syncGateway: getIt(),
      authGateway: getIt(),
    ),
  );

  if (occurrenceSyncCoordinator != null) {
    getIt.registerSingleton<OccurrenceSyncCoordinator>(occurrenceSyncCoordinator);
  } else {
    getIt.registerLazySingleton<OccurrenceSyncCoordinator>(
      () => DefaultOccurrenceSyncCoordinator(
        syncService: getIt(),
        queueRepository: getIt(),
      ),
    );
  }

  getIt.registerLazySingleton(
    () => OperatorProfileRepository(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(
    () => CatalogSyncService(getIt(), getIt()),
  );
  getIt.registerLazySingleton(
    () => BootstrapService(getIt(), getIt()),
  );

  if (syncForegroundPlatform != null) {
    getIt.registerSingleton<SyncForegroundPlatform>(syncForegroundPlatform);
  } else {
    getIt.registerLazySingleton<SyncForegroundPlatform>(
      createSyncForegroundPlatform,
    );
  }

  if (occurrenceSyncForegroundRunner != null) {
    getIt.registerSingleton<OccurrenceSyncForegroundRunner>(
      occurrenceSyncForegroundRunner,
    );
  } else {
    getIt.registerLazySingleton(
      () => OccurrenceSyncForegroundRunner(
        coordinator: getIt(),
        queueRepository: getIt(),
        platform: getIt(),
      ),
    );
  }
}

Future<void> _registerCaptureQualitySettings() async {
  if (getIt.isRegistered<CaptureQualitySettings>()) return;
  final settings = CaptureQualitySettings();
  await settings.load();
  getIt.registerSingleton<CaptureQualitySettings>(settings);
}

void _registerCaptureProduction() {
  final cameraSource = DeviceCameraSource(settings: getIt());
  getIt.registerLazySingleton<DeviceCameraSource>(() => cameraSource);
  _registerCaptureServices(
    cameraSource: cameraSource,
    locationSource: GeolocatorLocationSource(),
    hashService: CryptoHashService(),
  );
}

void _registerCaptureServices({
  required CameraSource cameraSource,
  required LocationSource locationSource,
  required HashService hashService,
}) {
  getIt.registerLazySingleton<CameraSource>(() => cameraSource);
  getIt.registerLazySingleton<LocationSource>(() => locationSource);
  getIt.registerLazySingleton<HashService>(() => hashService);
  getIt.registerLazySingleton(
    () => CaptureOccurrenceService(
      occurrenceRepository: getIt(),
      cameraSource: getIt(),
      locationSource: getIt(),
      hashService: getIt(),
      authGateway: getIt(),
      operatorProfileRepository: getIt(),
    ),
  );
}

class _UnimplementedAuthGateway implements AuthGateway {
  @override
  Stream<bool> get sessionStream => Stream.value(false);

  @override
  Stream<bool> get appAccessStream => Stream.value(false);

  @override
  bool get canAccessApp => false;

  @override
  bool get isSignedIn => false;

  @override
  String? get accessToken => null;

  @override
  String? get currentUserId => null;

  @override
  String? get loginNotice => null;

  @override
  void clearLoginNotice() {}

  @override
  Future<bool> hasPersistedSession() async => false;

  @override
  Future<bool> tryRefreshSessionSilently() async => false;

  @override
  Future<bool> shouldSignOutForUnauthorized({
    required int? statusCode,
    bool isNetworkError = false,
  }) async =>
      false;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut({String? loginNotice}) async {}
}
