import '../../platform/sync_foreground_platform.dart';
import '../repositories/sync_queue_repository.dart';
import 'occurrence_sync_coordinator.dart';
import 'occurrence_sync_service.dart';

/// Envolve [OccurrenceSyncCoordinator.syncNow] com Foreground Service Android.
///
/// Limite conhecido (MVP): FGS dataSync tem teto ~6h/dia no Android 15;
/// UIDT (ENI-40) fica pós-MVP.
class OccurrenceSyncForegroundRunner {
  OccurrenceSyncForegroundRunner({
    required OccurrenceSyncCoordinator coordinator,
    required SyncQueueRepository queueRepository,
    required SyncForegroundPlatform platform,
  })  : _coordinator = coordinator,
        _queueRepository = queueRepository,
        _platform = platform;

  final OccurrenceSyncCoordinator _coordinator;
  final SyncQueueRepository _queueRepository;
  final SyncForegroundPlatform _platform;

  Future<OccurrenceSyncResult?> runIfPending() async {
    if ((await _queueRepository.getPending()).totalCount == 0) return null;

    await _platform.requestNotificationPermission();
    await _platform.startForegroundService();

    try {
      return await _coordinator.syncNow();
    } finally {
      await _stopForegroundIfQueueEmpty();
    }
  }

  Future<void> _stopForegroundIfQueueEmpty() async {
    if ((await _queueRepository.getPending()).totalCount == 0) {
      await _platform.stopForegroundService();
    }
  }
}
