import 'dart:async';

import '../../platform/sync_foreground_platform.dart';
import '../../core/sync/sync_foreground_notification_text.dart';
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
    Duration? drainCycleTimeout,
  })  : _coordinator = coordinator,
        _queueRepository = queueRepository,
        _platform = platform,
        _drainCycleTimeout =
            drainCycleTimeout ?? const Duration(minutes: 30);

  final OccurrenceSyncCoordinator _coordinator;
  final SyncQueueRepository _queueRepository;
  final SyncForegroundPlatform _platform;
  final Duration _drainCycleTimeout;

  Future<OccurrenceSyncResult?>? _activeDrain;

  Future<OccurrenceSyncResult?> runIfPending() async {
    if ((await _queueRepository.getPending()).totalCount == 0) return null;

    final inFlight = _activeDrain;
    if (inFlight != null) return inFlight;

    final drain = _drainPendingQueue();
    _activeDrain = drain;
    try {
      return await drain;
    } finally {
      if (identical(_activeDrain, drain)) {
        _activeDrain = null;
      }
    }
  }

  Future<OccurrenceSyncResult?> _drainPendingQueue() async {
    await _platform.requestNotificationPermission();
    await _platform.startForegroundService();

    final deadline = DateTime.now().add(_drainCycleTimeout);

    try {
      OccurrenceSyncResult? aggregated;
      final initialTotal = (await _queueRepository.getPending()).totalCount;
      var completedThisDrain = 0;

      _coordinator.reportSyncProgress(current: 1, total: initialTotal);

      while ((await _queueRepository.getPending()).totalCount > 0) {
        if (DateTime.now().isAfter(deadline)) {
          aggregated = (aggregated ??
                  const OccurrenceSyncResult(
                    synced: 0,
                    failed: 0,
                    skipped: 0,
                  ))
              .merge(
            const OccurrenceSyncResult(
              synced: 0,
              failed: 0,
              skipped: 0,
              hadNetworkFailure: true,
            ),
          );
          final pendingAfter = await _queueRepository.getPending();
          await _platform.updateForegroundNotification(
            title: SyncForegroundNotificationText.titleWaiting,
            text: SyncForegroundNotificationText.waitingForConnection(
              pendingAfter.totalCount,
            ),
          );
          break;
        }

        final pendingBefore = await _queueRepository.getPending();
        final remaining = pendingBefore.totalCount;

        if (aggregated?.hadNetworkFailure == true) {
          await _platform.updateForegroundNotification(
            title: SyncForegroundNotificationText.titleWaiting,
            text: SyncForegroundNotificationText.waitingForConnection(remaining),
          );
          break;
        }

        final current = completedThisDrain + 1;

        _coordinator.reportSyncProgress(current: current, total: initialTotal);

        await _platform.updateForegroundNotification(
          title: SyncForegroundNotificationText.titleSending,
          text: SyncForegroundNotificationText.sendingProgress(
            current: current,
            total: initialTotal,
          ),
        );

        final timeLeft = deadline.difference(DateTime.now());
        if (timeLeft <= Duration.zero) {
          aggregated = (aggregated ??
                  const OccurrenceSyncResult(
                    synced: 0,
                    failed: 0,
                    skipped: 0,
                  ))
              .merge(
            const OccurrenceSyncResult(
              synced: 0,
              failed: 0,
              skipped: 0,
              hadNetworkFailure: true,
            ),
          );
          final pendingAfter = await _queueRepository.getPending();
          await _platform.updateForegroundNotification(
            title: SyncForegroundNotificationText.titleWaiting,
            text: SyncForegroundNotificationText.waitingForConnection(
              pendingAfter.totalCount,
            ),
          );
          break;
        }

        var syncTimedOut = false;
        final result = await _coordinator.syncNow().timeout(
          timeLeft,
          onTimeout: () {
            syncTimedOut = true;
            return const OccurrenceSyncResult(
              synced: 0,
              failed: 0,
              skipped: 0,
              hadNetworkFailure: true,
            );
          },
        );
        if (syncTimedOut) {
          _coordinator.recoverFromExternalTimeout();
        }
        if (result == null) break;

        aggregated = aggregated == null ? result : aggregated.merge(result);
        completedThisDrain += result.synced;

        if (result.unauthorized) break;

        if (result.hadNetworkFailure) {
          final pendingAfter = await _queueRepository.getPending();
          await _platform.updateForegroundNotification(
            title: SyncForegroundNotificationText.titleWaiting,
            text: SyncForegroundNotificationText.waitingForConnection(
              pendingAfter.totalCount,
            ),
          );
          break;
        }

        final pendingAfter = await _queueRepository.getPending();
        final madeProgress = result.synced > 0 ||
            pendingAfter.totalCount < pendingBefore.totalCount;
        if (!madeProgress) break;
      }

      return aggregated;
    } finally {
      _coordinator.clearSyncProgress();
      await _stopForegroundIfQueueEmpty();
    }
  }

  Future<void> _stopForegroundIfQueueEmpty() async {
    if ((await _queueRepository.getPending()).totalCount == 0) {
      await _platform.stopForegroundService();
    }
  }
}
