import '../../data/services/occurrence_sync_service.dart';

enum OccurrenceSyncStatus { idle, syncing }

class OccurrenceSyncLastResult {
  const OccurrenceSyncLastResult({
    required this.success,
    required this.at,
    this.syncResult,
    this.errorMessage,
  });

  final bool success;
  final DateTime at;
  final OccurrenceSyncResult? syncResult;
  final String? errorMessage;
}

class OccurrenceSyncCoordinatorState {
  const OccurrenceSyncCoordinatorState({
    this.status = OccurrenceSyncStatus.idle,
    this.lastResult,
    this.pendingCount = 0,
    this.syncProgressCurrent,
    this.syncProgressTotal,
  });

  final OccurrenceSyncStatus status;
  final OccurrenceSyncLastResult? lastResult;
  final int pendingCount;
  final int? syncProgressCurrent;
  final int? syncProgressTotal;

  bool get isSyncing => status == OccurrenceSyncStatus.syncing;

  bool get isSyncInProgress =>
      isSyncing || (syncProgressCurrent != null && syncProgressTotal != null);

  OccurrenceSyncCoordinatorState copyWith({
    OccurrenceSyncStatus? status,
    OccurrenceSyncLastResult? lastResult,
    int? pendingCount,
    int? syncProgressCurrent,
    int? syncProgressTotal,
    bool clearSyncProgress = false,
  }) {
    return OccurrenceSyncCoordinatorState(
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      pendingCount: pendingCount ?? this.pendingCount,
      syncProgressCurrent:
          clearSyncProgress ? null : (syncProgressCurrent ?? this.syncProgressCurrent),
      syncProgressTotal:
          clearSyncProgress ? null : (syncProgressTotal ?? this.syncProgressTotal),
    );
  }
}
