/// Status de negócio da ocorrência — distinto de [SyncState] (pipeline de sync).
abstract final class OccurrenceLifecycleStatus {
  static const draft = 'draft';
  static const pending = 'pending';
}
