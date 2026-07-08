import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/invalid_sync_transition_exception.dart';
import '../../core/sync/sync_entity_type.dart';
import '../../core/sync/sync_phase.dart';
import '../../core/sync/sync_state.dart';
import '../../core/sync/sync_state_machine.dart';
import '../local/app_database.dart';

class OccurrenceRepository {
  OccurrenceRepository(this._db, {SyncStateMachine? stateMachine, Uuid? uuid})
      : _stateMachine = stateMachine ?? const SyncStateMachine(),
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final SyncStateMachine _stateMachine;
  final Uuid _uuid;

  Future<Occurrence> createOccurrence({
    required String title,
    required String description,
    required String status,
    required String priority,
    required DateTime occurredAt,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? resolvedAt,
    String? observableId,
    String? categoryId,
    String? zonaId,
    DateTime? updatedAt,
    String? id,
    DateTime? createdLocalAt,
    DateTime? createdAt,
    String? reportedBy,
  }) async {
    final now = createdLocalAt ?? DateTime.now().toUtc();
    final domainCreatedAt = createdAt ?? now;
    final occurrenceId = id ?? _uuid.v4();

    final companion = OccurrencesCompanion.insert(
      id: occurrenceId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      occurredAt: occurredAt,
      createdAt: domainCreatedAt,
      createdLocalAt: now,
      location: Value(location),
      latitude: Value(latitude),
      longitude: Value(longitude),
      resolvedAt: Value(resolvedAt),
      observableId: Value(observableId),
      categoryId: Value(categoryId),
      zonaId: Value(zonaId),
      updatedAt: Value(updatedAt),
      reportedBy: Value(reportedBy),
    );

    await _db.into(_db.occurrences).insert(companion);
    return (_db.select(_db.occurrences)..where((t) => t.id.equals(occurrenceId)))
        .getSingle();
  }

  Future<OccurrenceMediaData> attachMedia({
    required String occurrenceId,
    required String mediaType,
    required String localPath,
    required String mimeType,
    int? sizeBytes,
    int? durationSeconds,
    int sortOrder = 0,
    String? originalName,
    String? contentHash,
    String? id,
    String? remotePath,
  }) async {
    final mediaId = id ?? _uuid.v4();

    await _db.into(_db.occurrenceMedia).insert(
          OccurrenceMediaCompanion.insert(
            id: mediaId,
            occurrenceId: occurrenceId,
            mediaType: mediaType,
            localPath: localPath,
            mimeType: mimeType,
            sortOrder: Value(sortOrder),
            sizeBytes: Value(sizeBytes),
            durationSeconds: Value(durationSeconds),
            originalName: Value(originalName),
            contentHash: Value(contentHash),
            remotePath: Value(remotePath),
          ),
        );

    return (_db.select(_db.occurrenceMedia)..where((t) => t.id.equals(mediaId)))
        .getSingle();
  }

  Future<Occurrence?> getById(String id) =>
      (_db.select(_db.occurrences)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Todas as ocorrências locais (rascunhos, enfileiradas e sincronizadas).
  Future<List<Occurrence>> listAll() {
    return (_db.select(_db.occurrences)
          ..orderBy([(t) => OrderingTerm.desc(t.createdLocalAt)]))
        .get();
  }

  /// Ocorrências do operador logado (ENI-97). Órfãs (`reported_by` null) ficam de fora.
  Future<List<Occurrence>> listForOperator(String operatorUid) {
    return (_db.select(_db.occurrences)
          ..where((t) => t.reportedBy.equals(operatorUid))
          ..orderBy([(t) => OrderingTerm.desc(t.createdLocalAt)]))
        .get();
  }

  /// Capturas legadas sem dono atribuído (pré ENI-97).
  Future<int> countOrphanOccurrences() async {
    final rows = await (_db.select(_db.occurrences)
          ..where((t) => t.reportedBy.isNull()))
        .get();
    return rows.length;
  }

  Future<List<OccurrenceMediaData>> getMedia(String occurrenceId) async {
    return (_db.select(_db.occurrenceMedia)
          ..where((t) => t.occurrenceId.equals(occurrenceId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<OccurrenceMediaData?> getPrimaryMedia(String occurrenceId) async {
    final media = await getMedia(occurrenceId);
    if (media.isEmpty) return null;
    return media.first;
  }

  Future<Occurrence> updateDraft({
    required String id,
    String? categoryId,
    String? observableId,
    String? zonaId,
    String? description,
    String? title,
    String? status,
  }) async {
    await _requireOccurrence(id);

    final companion = OccurrencesCompanion(
      categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
      observableId:
          observableId != null ? Value(observableId) : const Value.absent(),
      zonaId: zonaId != null ? Value(zonaId) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      title: title != null ? Value(title) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
      updatedAt: Value(DateTime.now().toUtc()),
    );

    await (_db.update(_db.occurrences)..where((t) => t.id.equals(id))).write(
          companion,
        );

    return _requireOccurrence(id);
  }

  Future<int> countMedia(String occurrenceId) async {
    final query = _db.select(_db.occurrenceMedia)
      ..where((t) => t.occurrenceId.equals(occurrenceId));
    return query.get().then((rows) => rows.length);
  }

  Future<bool> hasMedia(String occurrenceId) async =>
      (await countMedia(occurrenceId)) > 0;

  Future<int> nextMediaSortOrder(String occurrenceId) async {
    final media = await getMedia(occurrenceId);
    if (media.isEmpty) return 0;
    return media.last.sortOrder + 1;
  }

  Future<void> removeMedia(String mediaId) async {
    await (_db.delete(_db.occurrenceMedia)..where((t) => t.id.equals(mediaId)))
        .go();
  }

  Future<Occurrence> beginMediaUpload(String id) async {
    final occurrence = await _requireOccurrence(id);
    final hasAttachedMedia = await hasMedia(id);

    _stateMachine.assertTransition(
      from: occurrence.syncState,
      to: SyncState.mediaUploading,
      entityType: SyncEntityType.occurrence,
      hasMedia: hasAttachedMedia,
    );

    final now = DateTime.now().toUtc();
    await (_db.update(_db.occurrences)..where((t) => t.id.equals(id))).write(
          OccurrencesCompanion(
            syncState: Value(SyncState.mediaUploading),
            lastAttemptAt: Value(now),
          ),
        );

    return _requireOccurrence(id);
  }

  Future<Occurrence> markMediaDone(String id) async {
    final occurrence = await _requireOccurrence(id);
    final hasAttachedMedia = await hasMedia(id);

    _stateMachine.assertTransition(
      from: occurrence.syncState,
      to: SyncState.mediaDone,
      entityType: SyncEntityType.occurrence,
      hasMedia: hasAttachedMedia,
    );

    final now = DateTime.now().toUtc();
    await (_db.update(_db.occurrences)..where((t) => t.id.equals(id))).write(
          OccurrencesCompanion(
            syncState: Value(SyncState.mediaDone),
            mediaUploadedAt: Value(now),
            lastAttemptAt: Value(now),
          ),
        );

    return _requireOccurrence(id);
  }

  Future<Occurrence> beginJsonSync(String id) async {
    final occurrence = await _requireOccurrence(id);
    final hasAttachedMedia = await hasMedia(id);

    _stateMachine.assertTransition(
      from: occurrence.syncState,
      to: SyncState.jsonSyncing,
      entityType: SyncEntityType.occurrence,
      hasMedia: hasAttachedMedia,
    );

    final now = DateTime.now().toUtc();
    await (_db.update(_db.occurrences)..where((t) => t.id.equals(id))).write(
          OccurrencesCompanion(
            syncState: Value(SyncState.jsonSyncing),
            lastAttemptAt: Value(now),
          ),
        );

    return _requireOccurrence(id);
  }

  Future<Occurrence> markSynced(String id) async {
    final occurrence = await _requireOccurrence(id);

    _stateMachine.assertTransition(
      from: occurrence.syncState,
      to: SyncState.synced,
      entityType: SyncEntityType.occurrence,
    );

    final now = DateTime.now().toUtc();
    await (_db.update(_db.occurrences)..where((t) => t.id.equals(id))).write(
          OccurrencesCompanion(
            syncState: Value(SyncState.synced),
            syncedAt: Value(now),
            lastAttemptAt: Value(now),
            failedPhase: const Value(null),
            failedReason: const Value(null),
          ),
        );

    return _requireOccurrence(id);
  }

  Future<Occurrence> recordFailure(
    String id,
    SyncPhase phase,
    String reason,
  ) async {
    final occurrence = await _requireOccurrence(id);

    if (!_stateMachine.canFail(occurrence.syncState)) {
      throw InvalidSyncTransitionException(
        occurrence.syncState,
        SyncState.failed,
      );
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.occurrences)..where((t) => t.id.equals(id))).write(
          OccurrencesCompanion(
            syncState: Value(SyncState.failed),
            failedPhase: Value(phase),
            failedReason: Value(reason),
            retryCount: Value(occurrence.retryCount + 1),
            lastAttemptAt: Value(now),
          ),
        );

    return _requireOccurrence(id);
  }

  Future<void> setRemotePath(String mediaId, String remotePath) async {
    await (_db.update(_db.occurrenceMedia)..where((t) => t.id.equals(mediaId)))
        .write(
      OccurrenceMediaCompanion(remotePath: Value(remotePath)),
    );
  }

  Future<bool> allMediaUploaded(String occurrenceId) async {
    final media = await getMedia(occurrenceId);
    if (media.isEmpty) return true;
    return media.every((m) => m.remotePath != null);
  }

  static String canonicalStoragePath({
    required String occurrenceId,
    required String mediaId,
    required String mimeType,
  }) {
    final ext = extensionFromMimeType(mimeType);
    return 'occurrences/$occurrenceId/$mediaId.$ext';
  }

  static String extensionFromMimeType(String mimeType) {
    return switch (mimeType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'audio/mp4' => 'm4a',
      'audio/mpeg' => 'mp3',
      'video/mp4' => 'mp4',
      _ => mimeType.contains('/') ? mimeType.split('/').last : 'bin',
    };
  }

  Future<Occurrence> retry(String id) async {
    final occurrence = await _requireOccurrence(id);
    final failedPhase = occurrence.failedPhase;
    if (failedPhase == null) {
      throw InvalidSyncTransitionException(
        SyncState.failed,
        SyncState.localSaved,
        'missing failed_phase',
      );
    }

    final target = _stateMachine.stateForRetry(failedPhase);

    _stateMachine.assertTransition(
      from: SyncState.failed,
      to: target,
      entityType: SyncEntityType.occurrence,
      failedPhase: failedPhase,
    );

    await (_db.update(_db.occurrences)..where((t) => t.id.equals(id))).write(
          OccurrencesCompanion(
            syncState: Value(target),
            lastAttemptAt: Value(DateTime.now().toUtc()),
          ),
        );

    return _requireOccurrence(id);
  }

  Future<Occurrence> _requireOccurrence(String id) async {
    final occurrence = await getById(id);
    if (occurrence == null) {
      throw StateError('Occurrence not found: $id');
    }
    return occurrence;
  }
}
