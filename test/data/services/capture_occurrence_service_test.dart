import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_camera_source.dart';
import 'package:sentinel_app/data/fakes/fake_hash_service.dart';
import 'package:sentinel_app/data/fakes/fake_location_source.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/capture_occurrence_service.dart';
import 'package:sentinel_app/domain/models/capture_result.dart';

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
    test('captureDraft does not require accessToken (ENI-84)', () async {
      await getIt.reset();
      await configureDependenciesForTesting(
        db,
        authGateway: FakeAuthGateway(
          signedIn: false,
          persistedSession: true,
        ),
        cameraSource: camera,
        locationSource: location,
        hashService: hashService,
      );
      final offlineCapture = getIt<CaptureOccurrenceService>();

      final draft = await offlineCapture.captureDraft();

      expect(draft.occurrence.id, isNotEmpty);
      expect(draft.gpsAvailable, isTrue);
    });

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

    test('draft capture is not in sync pending queue until confirmed', () async {
      final draft = await captureService.captureDraft();

      final pending = await queueRepo.getPending();
      expect(pending.occurrences, isEmpty);

      final occurrence = await occurrenceRepo.getById(draft.occurrence.id);
      expect(occurrence!.status, 'draft');
      expect(occurrence.syncState, SyncState.localSaved);
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

    test('form update and confirm persist zona_id', () async {
      final draft = await captureService.captureDraft();

      await captureService.updateDraftForm(
        occurrenceId: draft.occurrence.id,
        zonaId: 'zone-42',
      );

      var updated = await occurrenceRepo.getById(draft.occurrence.id);
      expect(updated!.zonaId, 'zone-42');

      await captureService.confirmDraft(
        occurrenceId: draft.occurrence.id,
        zonaId: 'zone-42',
      );

      updated = await occurrenceRepo.getById(draft.occurrence.id);
      expect(updated!.status, 'pending');
      expect(updated.zonaId, 'zone-42');
    });

    test('confirm without note applies media-type defaults for API contract', () async {
      final draft = await captureService.captureDraft();

      await captureService.confirmDraft(
        occurrenceId: draft.occurrence.id,
        categoryId: 'cat-1',
        observableId: 'obs-1',
      );

      final updated = await occurrenceRepo.getById(draft.occurrence.id);
      expect(updated!.status, 'pending');
      expect(updated.title, 'Ocorrência');
      expect(updated.description, 'Registro fotográfico');
      expect(updated.description, isNotEmpty);

      final pending = await queueRepo.getPending();
      expect(pending.occurrences.map((o) => o.id), [draft.occurrence.id]);
    });

    test('confirm without note uses audio default when primary media is audio', () async {
      camera.nextMediaType = 'audio';
      camera.nextMimeType = 'audio/mpeg';
      final draft = await captureService.captureDraft();

      await captureService.confirmDraft(occurrenceId: draft.occurrence.id);

      final updated = await occurrenceRepo.getById(draft.occurrence.id);
      expect(updated!.description, 'Registro de áudio');
    });

    test('createDraftFromCapture persists video with duration', () async {
      final capture = CaptureResult(
        localPath: '/fake/captures/video.mp4',
        mediaType: 'video',
        mimeType: 'video/mp4',
        capturedAt: DateTime.utc(2026, 6, 15, 14, 0),
        sizeBytes: 5 * 1024 * 1024,
        durationSeconds: 42,
      );

      final draft = await captureService.createDraftFromCapture(capture);

      expect(hashService.hashCallCount, 1);
      final media = await occurrenceRepo.getMedia(draft.occurrence.id);
      expect(media, hasLength(1));
      expect(media.single.mediaType, 'video');
      expect(media.single.mimeType, 'video/mp4');
      expect(media.single.durationSeconds, 42);
      expect(media.single.localPath, '/fake/captures/video.mp4');
    });

    test('attachCaptureToDraft attaches video with durationSeconds', () async {
      final draft = await captureService.captureDraft();

      await captureService.attachCaptureToDraft(
        occurrenceId: draft.occurrence.id,
        capture: CaptureResult(
          localPath: '/fake/captures/clip.mp4',
          mediaType: 'video',
          mimeType: 'video/mp4',
          capturedAt: DateTime.utc(2026, 6, 15, 14, 30),
          sizeBytes: 2048,
          durationSeconds: 15,
        ),
      );

      final media = await occurrenceRepo.getMedia(draft.occurrence.id);
      expect(media, hasLength(2));
      final video = media.last;
      expect(video.mediaType, 'video');
      expect(video.mimeType, 'video/mp4');
      expect(video.durationSeconds, 15);
    });

    test('confirm without note uses video default when primary media is video',
        () async {
      final draft = await captureService.createDraftFromCapture(
        CaptureResult(
          localPath: '/fake/captures/video.mp4',
          mediaType: 'video',
          mimeType: 'video/mp4',
          capturedAt: DateTime.utc(2026, 6, 15, 14, 0),
        ),
      );

      await captureService.confirmDraft(occurrenceId: draft.occurrence.id);

      final updated = await occurrenceRepo.getById(draft.occurrence.id);
      expect(updated!.description, 'Registro de vídeo');
    });

    test('capture without GPS degrades gracefully with null coords', () async {
      location.returnNull = true;

      final draft = await captureService.captureDraft();

      expect(draft.gpsAvailable, isFalse);
      expect(draft.latitude, isNull);
      expect(draft.longitude, isNull);
      expect(draft.accuracy, isNull);

      final occurrence = await occurrenceRepo.getById(draft.occurrence.id);
      expect(occurrence!.latitude, isNull);
      expect(occurrence.longitude, isNull);
      expect(draft.media.localPath, isNotEmpty);
      expect(draft.contentHash, isNotEmpty);
    });

    test('capture is not blocked by offline fakes (no network dependency)', () async {
      final draft = await captureService.captureDraft();

      expect(draft.occurrence.syncState, SyncState.localSaved);
      expect(draft.media.localPath, isNotEmpty);
      expect(draft.contentHash, isNotEmpty);
    });

    test('addMediaToDraft appends media with incremental sort_order and distinct hash',
        () async {
      final draft = await captureService.captureDraft();

      await captureService.addMediaToDraft(draft.occurrence.id);
      await captureService.addMediaToDraft(draft.occurrence.id);

      final media = await occurrenceRepo.getMedia(draft.occurrence.id);
      expect(media, hasLength(3));
      expect(media.map((m) => m.sortOrder), [0, 1, 2]);

      final hashes = media.map((m) => m.contentHash).toSet();
      expect(hashes, hasLength(3));
      expect(camera.captureCallCount, 3);
      expect(hashService.hashCallCount, 3);
    });

    test('attachCaptureToDraft attaches pre-captured media without calling camera',
        () async {
      final draft = await captureService.captureDraft();
      final captureCountBefore = camera.captureCallCount;

      final capture = await camera.capture();
      await captureService.attachCaptureToDraft(
        occurrenceId: draft.occurrence.id,
        capture: capture,
      );

      final media = await occurrenceRepo.getMedia(draft.occurrence.id);
      expect(media, hasLength(2));
      expect(camera.captureCallCount, captureCountBefore + 1);
    });

    test('removeMediaFromDraft removes item from draft state', () async {
      final draft = await captureService.captureDraft();
      final second = await captureService.addMediaToDraft(draft.occurrence.id);

      await captureService.removeMediaFromDraft(
        occurrenceId: draft.occurrence.id,
        mediaId: second.id,
      );

      final media = await occurrenceRepo.getMedia(draft.occurrence.id);
      expect(media, hasLength(1));
      expect(media.single.id, draft.media.id);
    });

    test('confirm with multiple media enqueues occurrence for sync', () async {
      final draft = await captureService.captureDraft();
      await captureService.addMediaToDraft(draft.occurrence.id);
      await captureService.addMediaToDraft(draft.occurrence.id);

      await captureService.confirmDraft(occurrenceId: draft.occurrence.id);

      final media = await occurrenceRepo.getMedia(draft.occurrence.id);
      expect(media, hasLength(3));

      final pending = await queueRepo.getPending();
      expect(pending.occurrences.map((o) => o.id), [draft.occurrence.id]);
    });

    test('addMediaToDraft rejects non-draft occurrence', () async {
      final draft = await captureService.captureDraft();
      await captureService.confirmDraft(occurrenceId: draft.occurrence.id);

      expect(
        () => captureService.addMediaToDraft(draft.occurrence.id),
        throwsStateError,
      );
    });
  });
}
