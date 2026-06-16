import 'package:get_it/get_it.dart';

import '../data/fakes/fake_camera_source.dart';
import '../data/fakes/fake_hash_service.dart';
import '../data/fakes/fake_location_source.dart';
import '../data/local/app_database.dart';
import '../data/repositories/check_in_repository.dart';
import '../data/repositories/occurrence_repository.dart';
import '../data/repositories/sync_queue_repository.dart';
import '../data/services/capture_occurrence_service.dart';
import '../domain/services/camera_source.dart';
import '../domain/services/hash_service.dart';
import '../domain/services/location_source.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) {
    return;
  }

  final db = await AppDatabase.openDefault();
  await _registerCore(db);
  _registerCaptureFakes();
}

Future<void> configureDependenciesForTesting(
  AppDatabase db, {
  CameraSource? cameraSource,
  LocationSource? locationSource,
  HashService? hashService,
}) async {
  await getIt.reset();
  await _registerCore(db);
  _registerCaptureServices(
    cameraSource: cameraSource ?? FakeCameraSource(),
    locationSource: locationSource ?? FakeLocationSource(),
    hashService: hashService ?? FakeHashService(),
  );
}

Future<void> _registerCore(AppDatabase db) async {
  getIt.registerSingleton<AppDatabase>(db);
  getIt.registerLazySingleton(() => OccurrenceRepository(getIt()));
  getIt.registerLazySingleton(() => CheckInRepository(getIt()));
  getIt.registerLazySingleton(() => SyncQueueRepository(getIt()));
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

  // SyncGateway: contrato em domain/gateways/sync_gateway.dart — implementação na fase de upload.
}
