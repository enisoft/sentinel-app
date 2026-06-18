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
  });

  final OccurrenceSyncStatus status;
  final OccurrenceSyncLastResult? lastResult;
  final int pendingCount;

  bool get isSyncing => status == OccurrenceSyncStatus.syncing;

  OccurrenceSyncCoordinatorState copyWith({
    OccurrenceSyncStatus? status,
    OccurrenceSyncLastResult? lastResult,
    int? pendingCount,
  }) {
    return OccurrenceSyncCoordinatorState(
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }
}
