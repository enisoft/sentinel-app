import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/data/fakes/fake_sync_foreground_platform.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/occurrence_sync_coordinator.dart';
import 'package:sentinel_app/data/services/occurrence_sync_foreground_runner.dart';
import 'package:sentinel_app/data/services/occurrence_sync_service.dart';
import 'package:sentinel_app/platform/sync_foreground_platform.dart';

/// Runner de teste que conta chamadas a [runIfPending] sem executar sync real.
class CountingOccurrenceSyncForegroundRunner extends OccurrenceSyncForegroundRunner {
  CountingOccurrenceSyncForegroundRunner({
    required super.coordinator,
    required super.queueRepository,
    required super.platform,
  });

  int runIfPendingCallCount = 0;

  @override
  Future<OccurrenceSyncResult?> runIfPending() async {
    runIfPendingCallCount++;
    return null;
  }
}

CountingOccurrenceSyncForegroundRunner createCountingForegroundRunner({
  required OccurrenceSyncCoordinator coordinator,
  required SyncQueueRepository queueRepository,
  SyncForegroundPlatform? platform,
}) {
  return CountingOccurrenceSyncForegroundRunner(
    coordinator: coordinator,
    queueRepository: queueRepository,
    platform: platform ?? FakeSyncForegroundPlatform(),
  );
}

/// Substitui o runner registrado no getIt por um contador (chamar após [configureDependenciesForTesting]).
CountingOccurrenceSyncForegroundRunner installCountingForegroundRunner() {
  final runner = CountingOccurrenceSyncForegroundRunner(
    coordinator: getIt<OccurrenceSyncCoordinator>(),
    queueRepository: getIt<SyncQueueRepository>(),
    platform: FakeSyncForegroundPlatform(),
  );
  if (getIt.isRegistered<OccurrenceSyncForegroundRunner>()) {
    getIt.unregister<OccurrenceSyncForegroundRunner>();
  }
  getIt.registerSingleton<OccurrenceSyncForegroundRunner>(runner);
  return runner;
}
