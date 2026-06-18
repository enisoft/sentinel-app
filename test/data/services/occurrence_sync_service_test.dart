import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/auth/auth_messages.dart';
import 'package:sentinel_app/core/sync/sync_phase.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_media_uploader.dart';
import 'package:sentinel_app/data/fakes/fake_sync_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_exception.dart';
import 'package:sentinel_app/data/remote/media_upload_exception.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/occurrence_sync_service.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  late SyncQueueRepository queueRepo;
  late FakeMediaUploader fakeMediaUploader;
  late FakeSyncGateway fakeGateway;
  late FakeAuthGateway fakeAuth;
  late OccurrenceSyncService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
    queueRepo = SyncQueueRepository(db);
    fakeMediaUploader = FakeMediaUploader(occurrenceRepository: occurrenceRepo);
    fakeGateway = FakeSyncGateway(mediaUploader: fakeMediaUploader);
    fakeAuth = FakeAuthGateway();
    service = OccurrenceSyncService(
      queueRepository: queueRepo,
      occurrenceRepository: occurrenceRepo,
      syncGateway: fakeGateway,
      authGateway: fakeAuth,
    );
  });

  tearDown(() async {
    fakeAuth.dispose();
    await db.close();
  });

  Future<void> seedOccurrence({
    required String id,
    bool withMedia = false,
    String? mediaId,
    int extraMedia = 0,
  }) async {
    await occurrenceRepo.createOccurrence(
      id: id,
      title: 'Test',
      description: 'Desc',
      status: 'pending',
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 1),
    );
    if (withMedia) {
      await occurrenceRepo.attachMedia(
        id: mediaId ?? 'media-1-$id',
        occurrenceId: id,
        mediaType: 'image',
        localPath: '/tmp/photo-$id.jpg',
        mimeType: 'image/jpeg',
      );
      for (var i = 0; i < extraMedia; i++) {
        await occurrenceRepo.attachMedia(
          id: 'media-extra-$i-$id',
          occurrenceId: id,
          mediaType: 'image',
          localPath: '/tmp/photo-extra-$i-$id.jpg',
          mimeType: 'image/jpeg',
          sortOrder: i + 1,
        );
      }
    }
  }

  test('confirmed id in data.ids marks occurrence synced', () async {
    await seedOccurrence(id: 'occ-sync', withMedia: true);
    fakeGateway.confirmedIds = ['occ-sync'];

    final result = await service.processPending();

    expect(result.synced, 1);
    expect(fakeMediaUploader.uploadCallCount, 1);
    expect(fakeGateway.syncCallCount, 1);
    final occurrence = await occurrenceRepo.getById('occ-sync');
    expect(occurrence!.syncState, SyncState.synced);
    expect(occurrence.syncedAt, isNotNull);
  });

  test('single media upload reaches media_done then json_syncing', () async {
    await seedOccurrence(
      id: 'occ-one-media',
      withMedia: true,
      mediaId: '8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00',
    );
    fakeGateway.confirmedIds = [];

    await service.processPending();

    final media = await occurrenceRepo.getMedia('occ-one-media');
    expect(
      media.single.remotePath,
      'occurrences/occ-one-media/8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00.jpg',
    );
    final occurrence = await occurrenceRepo.getById('occ-one-media');
    expect(occurrence!.syncState, SyncState.jsonSyncing);
    expect(fakeMediaUploader.uploadCallCount, 1);
    expect(fakeGateway.uploadCallCount, 1);
    expect(fakeGateway.syncCallCount, 1);
  });

  test('two media items reach media_done only when both uploaded', () async {
    await seedOccurrence(
      id: 'occ-two-media',
      withMedia: true,
      mediaId: 'm1-two',
      extraMedia: 1,
    );
    fakeGateway.confirmedIds = ['occ-two-media'];

    final result = await service.processPending();

    expect(result.synced, 1);
    final media = await occurrenceRepo.getMedia('occ-two-media');
    expect(media, hasLength(2));
    expect(media.every((m) => m.remotePath != null), isTrue);
    expect(
      media[0].remotePath,
      'occurrences/occ-two-media/m1-two.jpg',
    );
    expect(
      media[1].remotePath,
      'occurrences/occ-two-media/media-extra-0-occ-two-media.jpg',
    );
  });

  test('media upload exception records media_uploading phase and retries on next cycle',
      () async {
    await seedOccurrence(id: 'occ-upload-fail', withMedia: true);
    fakeMediaUploader.uploadException =
        MediaUploadException(500, 'Rede indisponível.');

    await service.processPending();

    var occurrence = await occurrenceRepo.getById('occ-upload-fail');
    expect(occurrence!.syncState, SyncState.failed);
    expect(occurrence.failedPhase, SyncPhase.mediaUploading);
    expect(occurrence.retryCount, 1);
    expect(fakeGateway.syncCallCount, 0);
    expect(fakeMediaUploader.uploadCallCount, 1);

    fakeMediaUploader.uploadException = null;
    fakeGateway.confirmedIds = ['occ-upload-fail'];

    final result = await service.processPending();

    expect(result.synced, 1);
    occurrence = await occurrenceRepo.getById('occ-upload-fail');
    expect(occurrence!.syncState, SyncState.synced);
  });

  test('media upload failure records media_uploading phase and retries partial',
      () async {
    const occId = 'occ-partial-fail';
    await seedOccurrence(
      id: occId,
      withMedia: true,
      mediaId: 'm1-partial',
      extraMedia: 1,
    );

    fakeMediaUploader.onUpload = (id) async {
      final items = await occurrenceRepo.getMedia(id);
      final pending = items.where((m) => m.remotePath == null).toList();
      if (pending.isEmpty) return;
      final first = pending.first;
      await occurrenceRepo.setRemotePath(
        first.id,
        OccurrenceRepository.canonicalStoragePath(
          occurrenceId: id,
          mediaId: first.id,
          mimeType: first.mimeType,
        ),
      );
      if (pending.length > 1) {
        throw MediaUploadException(500, 'Falha no segundo arquivo.');
      }
    };

    await service.processPending();

    var occurrence = await occurrenceRepo.getById(occId);
    expect(occurrence!.syncState, SyncState.failed);
    expect(occurrence.failedPhase, SyncPhase.mediaUploading);
    expect(occurrence.retryCount, 1);
    expect(fakeGateway.syncCallCount, 0);

    fakeMediaUploader.uploadException = null;
    fakeGateway.confirmedIds = [occId];
    fakeGateway.syncCallCount = 0;

    final result = await service.processPending();

    expect(result.synced, 1);
    expect(fakeMediaUploader.uploadCallCount, 2);
    final media = await occurrenceRepo.getMedia(occId);
    expect(media.every((m) => m.remotePath != null), isTrue);
    occurrence = await occurrenceRepo.getById(occId);
    expect(occurrence!.syncState, SyncState.synced);
  });

  test('missing id in response keeps occurrence pending without synced', () async {
    await seedOccurrence(id: 'occ-pending', withMedia: true);
    fakeGateway.confirmedIds = [];

    await service.processPending();

    final occurrence = await occurrenceRepo.getById('occ-pending');
    expect(occurrence!.syncState, SyncState.jsonSyncing);
    expect(occurrence.syncedAt, isNull);
  });

  test('401 on JSON triggers signOut', () async {
    await seedOccurrence(id: 'occ-401');
    fakeGateway.syncException = ApiException(401, 'Token inválido.');

    final result = await service.processPending();

    expect(result.unauthorized, isTrue);
    expect(fakeAuth.isSignedIn, isFalse);
    expect(fakeAuth.loginNotice, AuthMessages.sessionExpired);
  });

  test('401 on media upload triggers signOut', () async {
    await seedOccurrence(id: 'occ-media-401', withMedia: true);
    fakeMediaUploader.uploadException =
        MediaUploadException(401, 'Token inválido.');

    final result = await service.processPending();

    expect(result.unauthorized, isTrue);
    expect(fakeGateway.syncCallCount, 0);
    expect(fakeAuth.loginNotice, AuthMessages.sessionExpired);
  });

  test('5xx records failure with json_syncing phase and increments retry_count', () async {
    await seedOccurrence(id: 'occ-500');
    fakeGateway.syncException = ApiException(500, 'Erro interno.');

    await service.processPending();

    final occurrence = await occurrenceRepo.getById('occ-500');
    expect(occurrence!.syncState, SyncState.failed);
    expect(occurrence.failedPhase, SyncPhase.jsonSyncing);
    expect(occurrence.retryCount, 1);
  });

  test('422 records non-retryable validation failure', () async {
    await seedOccurrence(id: 'occ-422');
    fakeGateway.syncException = ApiException(422, 'title é obrigatório.');

    await service.processPending();

    final occurrence = await occurrenceRepo.getById('occ-422');
    expect(occurrence!.syncState, SyncState.failed);
    expect(occurrence.failedReason, startsWith('validation:'));
    expect(occurrence.retryCount, 1);
  });

  test('422 failure is skipped on next processPending cycle', () async {
    await seedOccurrence(id: 'occ-skip');
    fakeGateway.syncException = ApiException(422, 'FK inválida.');

    await service.processPending();
    fakeGateway.syncException = null;
    fakeGateway.confirmedIds = ['occ-skip'];
    fakeGateway.syncCallCount = 0;

    final result = await service.processPending();

    expect(result.skipped, 1);
    expect(result.synced, 0);
    expect(fakeGateway.syncCallCount, 0);
    final occurrence = await occurrenceRepo.getById('occ-skip');
    expect(occurrence!.syncState, SyncState.failed);
  });

  test('retryable failure is retried on next cycle', () async {
    await seedOccurrence(id: 'occ-retry');
    fakeGateway.syncException = ApiException(500, 'timeout');

    await service.processPending();

    fakeGateway.syncException = null;
    fakeGateway.confirmedIds = ['occ-retry'];

    final result = await service.processPending();

    expect(result.synced, 1);
    final occurrence = await occurrenceRepo.getById('occ-retry');
    expect(occurrence!.syncState, SyncState.synced);
  });

  test('processPending ignores unconfirmed drafts', () async {
    await occurrenceRepo.createOccurrence(
      id: 'draft-only',
      title: '',
      description: '',
      status: 'draft',
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 1),
    );
    await occurrenceRepo.attachMedia(
      id: 'media-draft',
      occurrenceId: 'draft-only',
      mediaType: 'image',
      localPath: '/tmp/photo-draft.jpg',
      mimeType: 'image/jpeg',
    );
    fakeGateway.confirmedIds = ['draft-only'];

    final result = await service.processPending();

    expect(result.synced, 0);
    expect(result.failed, 0);
    expect(result.skipped, 0);
    expect(fakeGateway.syncCallCount, 0);
    final occurrence = await occurrenceRepo.getById('draft-only');
    expect(occurrence!.status, 'draft');
    expect(occurrence.syncState, SyncState.localSaved);
  });
}
