import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/auth/auth_messages.dart';
import 'package:sentinel_app/core/sync/sync_phase.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_sync_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_exception.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/occurrence_sync_service.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  late SyncQueueRepository queueRepo;
  late FakeSyncGateway fakeGateway;
  late FakeAuthGateway fakeAuth;
  late OccurrenceSyncService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
    queueRepo = SyncQueueRepository(db);
    fakeGateway = FakeSyncGateway();
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
        occurrenceId: id,
        mediaType: 'image',
        localPath: '/tmp/photo.jpg',
        mimeType: 'image/jpeg',
      );
    }
  }

  test('confirmed id in data.ids marks occurrence synced', () async {
    await seedOccurrence(id: 'occ-sync', withMedia: true);
    fakeGateway.confirmedIds = ['occ-sync'];

    final result = await service.processPending();

    expect(result.synced, 1);
    final occurrence = await occurrenceRepo.getById('occ-sync');
    expect(occurrence!.syncState, SyncState.synced);
    expect(occurrence.syncedAt, isNotNull);
  });

  test('missing id in response keeps occurrence pending without synced', () async {
    await seedOccurrence(id: 'occ-pending', withMedia: true);
    fakeGateway.confirmedIds = [];

    await service.processPending();

    final occurrence = await occurrenceRepo.getById('occ-pending');
    expect(occurrence!.syncState, SyncState.jsonSyncing);
    expect(occurrence.syncedAt, isNull);
  });

  test('401 triggers signOut', () async {
    await seedOccurrence(id: 'occ-401');
    fakeGateway.syncException = ApiException(401, 'Token inválido.');

    final result = await service.processPending();

    expect(result.unauthorized, isTrue);
    expect(fakeAuth.isSignedIn, isFalse);
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
}
