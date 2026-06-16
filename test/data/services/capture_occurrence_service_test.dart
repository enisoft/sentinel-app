import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_camera_source.dart';
import 'package:sentinel_app/data/fakes/fake_hash_service.dart';
import 'package:sentinel_app/data/fakes/fake_location_source.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/capture_occurrence_service.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  late SyncQueueRepository queueRepo;
  late FakeCameraSource camera;
  late FakeLocationSource location;
  late FakeHashService hashService;
  late CaptureOccurrenceService captureService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    camera = FakeCameraSource(
      nextPath: '/fake/captures/test-photo.jpg',
      nextCapturedAt: DateTime.utc(2026, 6, 15, 14, 0),
    );
    location = FakeLocationSource(
      nextLatitude: -25.5,
      nextLongitude: -49.2,
      nextAccuracy: 10.0,
      nextCapturedAt: DateTime.utc(2026, 6, 15, 14, 0),
    );
    hashService = FakeHashService(prefix: 'test-sha256');

    await configureDependenciesForTesting(
      db,
      cameraSource: camera,
      locationSource: location,
      hashService: hashService,
    );

    occurrenceRepo = getIt<OccurrenceRepository>();
    queueRepo = getIt<SyncQueueRepository>();
    captureService = getIt<CaptureOccurrenceService>();
  });

  tearDown(() async {
    await db.close();
  });

  group('CaptureOccurrenceService', () {
    test('fake capture creates local_saved draft with media and metadata', () async {
      final draft = await captureService.captureDraft();

      expect(camera.captureCallCount, 1);
      expect(location.positionCallCount, 1);
      expect(hashService.hashCallCount, 1);

      final occurrence = await occurrenceRepo.getById(draft.occurrence.id);
      expect(occurrence, isNotNull);
      expect(occurrence!.syncState, SyncState.localSaved);
      expect(occurrence.status, 'draft');
      expect(occurrence.latitude, -25.5);
      expect(occurrence.longitude, -49.2);

      final media = await occurrenceRepo.getMedia(occurrence.id);
      expect(media, hasLength(1));
      expect(media.single.localPath, '/fake/captures/test-photo.jpg');
      expect(media.single.contentHash, draft.contentHash);
      expect(media.single.contentHash, startsWith('test-sha256:'));
    });

    test('form update and confirm enqueue occurrence in pending sync', () async {
      final draft = await captureService.captureDraft();

      await captureService.updateDraftForm(
        occurrenceId: draft.occurrence.id,
        categoryId: 'cat-1',
        observableId: 'obs-1',
        note: 'Nota de teste',
      );

      var updated = await occurrenceRepo.getById(draft.occurrence.id);
      expect(updated!.categoryId, 'cat-1');
      expect(updated.observableId, 'obs-1');
      expect(updated.description, 'Nota de teste');

      await captureService.confirmDraft(
        occurrenceId: draft.occurrence.id,
        categoryId: 'cat-1',
        observableId: 'obs-1',
        note: 'Nota de teste',
      );

      updated = await occurrenceRepo.getById(draft.occurrence.id);
      expect(updated!.status, 'pending');
      expect(updated.syncState, SyncState.localSaved);

      final pending = await queueRepo.getPending();
      expect(pending.occurrences.map((o) => o.id), [draft.occurrence.id]);
    });

    test('capture is not blocked by offline fakes (no network dependency)', () async {
      final draft = await captureService.captureDraft();

      expect(draft.occurrence.syncState, SyncState.localSaved);
      expect(draft.media.localPath, isNotEmpty);
      expect(draft.contentHash, isNotEmpty);
    });
  });
}
