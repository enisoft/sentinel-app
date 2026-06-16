import 'package:get_it/get_it.dart';

import '../data/local/app_database.dart';
import '../data/repositories/check_in_repository.dart';
import '../data/repositories/occurrence_repository.dart';
import '../data/repositories/sync_queue_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) {
    return;
  }

  final db = await AppDatabase.openDefault();
  getIt.registerSingleton<AppDatabase>(db);
  getIt.registerLazySingleton(() => OccurrenceRepository(getIt()));
  getIt.registerLazySingleton(() => CheckInRepository(getIt()));
  getIt.registerLazySingleton(() => SyncQueueRepository(getIt()));

  // SyncGateway: contrato em domain/gateways/sync_gateway.dart — implementação na fase de upload.
}

Future<void> configureDependenciesForTesting(AppDatabase db) async {
  await getIt.reset();
  getIt.registerSingleton<AppDatabase>(db);
  getIt.registerLazySingleton(() => OccurrenceRepository(getIt()));
  getIt.registerLazySingleton(() => CheckInRepository(getIt()));
  getIt.registerLazySingleton(() => SyncQueueRepository(getIt()));
}
