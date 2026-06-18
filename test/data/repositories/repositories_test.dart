import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/sync/sync_phase.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/check_in_repository.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  late CheckInRepository checkInRepo;
  late SyncQueueRepository queueRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
    checkInRepo = CheckInRepository(db);
    queueRepo = SyncQueueRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('OccurrenceRepository', () {
    test('creates occurrence in localSaved with created_local_at', () async {
      final occurredAt = DateTime.utc(2026, 6, 10, 14, 30);
      final createdLocalAt = DateTime.utc(2026, 6, 10, 14, 35);

      final occurrence = await occurrenceRepo.createOccurrence(
        id: 'occ-1',
        title: 'Test',
        description: 'Desc',
        status: 'pending',
        priority: 'high',
        occurredAt: occurredAt,
        createdLocalAt: createdLocalAt,
      );

      expect(occurrence.id, 'occ-1');
      expect(occurrence.syncState, SyncState.localSaved);
      expect(occurrence.retryCount, 0);
      expect(occurrence.createdLocalAt.toUtc(), createdLocalAt);
      expect(occurrence.createdAt.toUtc(), createdLocalAt);
    });

    test('transitions occurrence with media through pipeline', () async {
      await occurrenceRepo.createOccurrence(
        id: 'occ-media',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'medium',
        occurredAt: DateTime.utc(2026, 1, 1),
      );
      await occurrenceRepo.attachMedia(
        occurrenceId: 'occ-media',
        mediaType: 'image',
        localPath: '/tmp/photo.jpg',
        mimeType: 'image/jpeg',
      );

      var current = await occurrenceRepo.beginMediaUpload('occ-media');
      expect(current.syncState, SyncState.mediaUploading);

      current = await occurrenceRepo.markMediaDone('occ-media');
      expect(current.syncState, SyncState.mediaDone);
      expect(current.mediaUploadedAt, isNotNull);

      current = await occurrenceRepo.beginJsonSync('occ-media');
      expect(current.syncState, SyncState.jsonSyncing);

      current = await occurrenceRepo.markSynced('occ-media');
      expect(current.syncState, SyncState.synced);
      expect(current.syncedAt, isNotNull);
    });

    test('occurrence without media skips upload states', () async {
      await occurrenceRepo.createOccurrence(
        id: 'occ-plain',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'low',
        occurredAt: DateTime.utc(2026, 1, 1),
      );

      final current = await occurrenceRepo.markMediaDone('occ-plain');
      expect(current.syncState, SyncState.mediaDone);

      final synced = await occurrenceRepo.beginJsonSync('occ-plain');
      expect(synced.syncState, SyncState.jsonSyncing);
    });

    test('recordFailure increments retry and stores phase/reason', () async {
      await occurrenceRepo.createOccurrence(
        id: 'occ-fail',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'low',
        occurredAt: DateTime.utc(2026, 1, 1),
      );
      await occurrenceRepo.markMediaDone('occ-fail');
      await occurrenceRepo.beginJsonSync('occ-fail');

      final failed = await occurrenceRepo.recordFailure(
        'occ-fail',
        SyncPhase.jsonSyncing,
        'HTTP 500',
      );

      expect(failed.syncState, SyncState.failed);
      expect(failed.failedPhase, SyncPhase.jsonSyncing);
      expect(failed.failedReason, 'HTTP 500');
      expect(failed.retryCount, 1);
      expect(failed.lastAttemptAt, isNotNull);
    });

    test('retry restores jsonSyncing after json failure', () async {
      await occurrenceRepo.createOccurrence(
        id: 'occ-retry',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'low',
        occurredAt: DateTime.utc(2026, 1, 1),
      );
      await occurrenceRepo.markMediaDone('occ-retry');
      await occurrenceRepo.beginJsonSync('occ-retry');
      await occurrenceRepo.recordFailure('occ-retry', SyncPhase.jsonSyncing, 'timeout');

      final retried = await occurrenceRepo.retry('occ-retry');
      expect(retried.syncState, SyncState.jsonSyncing);
    });
  });

  group('CheckInRepository', () {
    test('creates check-in and syncs without media pipeline', () async {
      final checkIn = await checkInRepo.createCheckIn(
        id: 'ci-1',
        latitude: -25.5,
        longitude: -49.1,
        accuracy: 12.5,
        capturedAt: DateTime.utc(2026, 6, 14, 10, 0),
        note: 'Patrulha',
      );

      expect(checkIn.syncState, SyncState.localSaved);

      final syncing = await checkInRepo.beginJsonSync('ci-1');
      expect(syncing.syncState, SyncState.jsonSyncing);

      final synced = await checkInRepo.markSynced('ci-1');
      expect(synced.syncState, SyncState.synced);
    });
  });

  group('SyncQueueRepository', () {
    test('getPending excludes synced and includes failed/intermediate', () async {
      await occurrenceRepo.createOccurrence(
        id: 'pending-occ',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'low',
        occurredAt: DateTime.utc(2026, 1, 1),
      );

      await occurrenceRepo.createOccurrence(
        id: 'synced-occ',
        title: 'T2',
        description: 'D2',
        status: 'pending',
        priority: 'low',
        occurredAt: DateTime.utc(2026, 1, 2),
      );
      await occurrenceRepo.markMediaDone('synced-occ');
      await occurrenceRepo.beginJsonSync('synced-occ');
      await occurrenceRepo.markSynced('synced-occ');

      await checkInRepo.createCheckIn(
        id: 'failed-ci',
        latitude: 1,
        longitude: 2,
        accuracy: 3,
        capturedAt: DateTime.utc(2026, 1, 3),
      );
      await checkInRepo.beginJsonSync('failed-ci');
      await checkInRepo.recordFailure('failed-ci', SyncPhase.jsonSyncing, 'offline');

      final pending = await queueRepo.getPending();

      expect(pending.occurrences.map((o) => o.id), ['pending-occ']);
      expect(pending.checkIns.single.id, 'failed-ci');
      expect(pending.checkIns.single.retryCount, 1);
      expect(pending.totalCount, 2);
    });

    test('getPending excludes unconfirmed drafts', () async {
      await occurrenceRepo.createOccurrence(
        id: 'draft-occ',
        title: '',
        description: '',
        status: 'draft',
        priority: 'low',
        occurredAt: DateTime.utc(2026, 1, 1),
      );

      await occurrenceRepo.createOccurrence(
        id: 'confirmed-occ',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'low',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      final pending = await queueRepo.getPending();

      expect(pending.occurrences.map((o) => o.id), ['confirmed-occ']);
      expect(pending.totalCount, 1);
    });

    test('watchPending emits as items enter, change state, and leave queue', () async {
      final emissions = <PendingSyncSnapshot>[];
      late StreamSubscription<PendingSyncSnapshot> subscription;

      subscription = queueRepo.watchPending().listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, isNotEmpty);
      expect(emissions.last.totalCount, 0);

      await occurrenceRepo.createOccurrence(
        id: 'stream-occ',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'low',
        occurredAt: DateTime.utc(2026, 1, 1),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.occurrences.map((o) => o.id), ['stream-occ']);
      expect(emissions.last.occurrences.single.syncState, SyncState.localSaved);

      await occurrenceRepo.attachMedia(
        occurrenceId: 'stream-occ',
        mediaType: 'image',
        localPath: '/tmp/stream.jpg',
        mimeType: 'image/jpeg',
      );
      await occurrenceRepo.beginMediaUpload('stream-occ');
      await Future<void>.delayed(Duration.zero);

      expect(
        emissions.last.occurrences.single.syncState,
        SyncState.mediaUploading,
      );

      await checkInRepo.createCheckIn(
        id: 'stream-ci',
        latitude: 1,
        longitude: 2,
        accuracy: 3,
        capturedAt: DateTime.utc(2026, 1, 3),
      );
      await checkInRepo.beginJsonSync('stream-ci');
      await checkInRepo.recordFailure(
        'stream-ci',
        SyncPhase.jsonSyncing,
        'timeout',
      );
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.totalCount, 2);
      expect(emissions.last.checkIns.single.id, 'stream-ci');
      expect(emissions.last.checkIns.single.syncState, SyncState.failed);

      await occurrenceRepo.markMediaDone('stream-occ');
      await occurrenceRepo.beginJsonSync('stream-occ');
      await occurrenceRepo.markSynced('stream-occ');
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.occurrences, isEmpty);
      expect(emissions.last.checkIns.single.id, 'stream-ci');

      await checkInRepo.retry('stream-ci');
      await checkInRepo.markSynced('stream-ci');
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.totalCount, 0);

      await subscription.cancel();
    });
  });
}
