import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../data/fakes/fake_camera_source.dart';
import '../data/fakes/fake_hash_service.dart';
import '../data/fakes/fake_location_source.dart';
import '../data/gateways/supabase_auth_gateway.dart';
import '../data/local/app_database.dart';
import '../data/remote/api_client.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/check_in_repository.dart';
import '../data/repositories/occurrence_repository.dart';
import '../data/repositories/operator_profile_repository.dart';
import '../data/repositories/sync_queue_repository.dart';
import '../data/services/bootstrap_service.dart';
import '../data/services/capture_occurrence_service.dart';
import '../data/services/catalog_sync_service.dart';
import '../domain/gateways/auth_gateway.dart';
import '../domain/services/camera_source.dart';
import '../domain/services/hash_service.dart';
import '../domain/services/location_source.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) {
    return;
  }

  final config = await AppConfig.load();

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );

  getIt.registerSingleton<AppConfig>(config);

  final db = await AppDatabase.openDefault();
  await _registerCore(db, config);
  _registerCaptureFakes();
}

Future<void> configureDependenciesForTesting(
  AppDatabase db, {
  AppConfig? config,
  AuthGateway? authGateway,
  ApiClient? apiClient,
  CameraSource? cameraSource,
  LocationSource? locationSource,
  HashService? hashService,
}) async {
  await getIt.reset();

  final testConfig = config ??
      AppConfig.fromMap({
        'SUPABASE_URL': 'http://localhost:54321',
        'SUPABASE_ANON_KEY': 'test-anon-key',
        'API_BASE_URL': 'http://localhost:8000/api/v1',
      });

  getIt.registerSingleton<AppConfig>(testConfig);

  final auth = authGateway ?? _UnimplementedAuthGateway();
  getIt.registerSingleton<AuthGateway>(auth);

  await _registerCore(db, testConfig, apiClient: apiClient);

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
}) async {
  getIt.registerSingleton<AppDatabase>(db);
  getIt.registerLazySingleton(() => OccurrenceRepository(getIt()));
  getIt.registerLazySingleton(() => CheckInRepository(getIt()));
  getIt.registerLazySingleton(() => SyncQueueRepository(getIt()));
  getIt.registerLazySingleton(() => CatalogRepository(getIt()));

  if (!getIt.isRegistered<AuthGateway>()) {
    getIt.registerLazySingleton<AuthGateway>(
      () => SupabaseAuthGateway(Supabase.instance.client),
    );
  }

  getIt.registerLazySingleton<ApiClient>(
    () => apiClient ?? ApiClient(config: config, authGateway: getIt()),
  );

  getIt.registerLazySingleton(
    () => OperatorProfileRepository(getIt(), getIt()),
  );
  getIt.registerLazySingleton(
    () => CatalogSyncService(getIt(), getIt()),
  );
  getIt.registerLazySingleton(
    () => BootstrapService(getIt(), getIt()),
  );
}

void _registerCaptureFakes() {
  _registerCaptureServices(
    cameraSource: FakeCameraSource(),
    locationSource: FakeLocationSource(),
    hashService: FakeHashService(),
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
    ),
  );
}

class _UnimplementedAuthGateway implements AuthGateway {
  @override
  Stream<bool> get sessionStream => Stream.value(false);

  @override
  bool get isSignedIn => false;

  @override
  String? get accessToken => null;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}
