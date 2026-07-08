import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_camera_source.dart';
import 'package:sentinel_app/data/fakes/fake_hash_service.dart';
import 'package:sentinel_app/data/fakes/fake_location_source.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/services/capture_occurrence_service.dart';
import 'package:sentinel_app/data/sync/sync_payload_serializer.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  const serializer = SyncPayloadSerializer();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  group('OccurrenceRepository — reported_by (ENI-97)', () {
    test('listForOperator returns only occurrences owned by uid', () async {
      await occurrenceRepo.createOccurrence(
        id: 'occ-a-1',
        title: 'A1',
        description: 'd',
        status: 'pending',
        priority: 'medium',
        occurredAt: DateTime.utc(2026, 1, 1),
        reportedBy: 'operator-a',
      );
      await occurrenceRepo.createOccurrence(
        id: 'occ-b-1',
        title: 'B1',
        description: 'd',
        status: 'pending',
        priority: 'medium',
        occurredAt: DateTime.utc(2026, 1, 2),
        reportedBy: 'operator-b',
      );
      await occurrenceRepo.createOccurrence(
        id: 'orphan-1',
        title: 'Orphan',
        description: 'd',
        status: 'pending',
        priority: 'medium',
        occurredAt: DateTime.utc(2026, 1, 3),
      );

      final forA = await occurrenceRepo.listForOperator('operator-a');
      final forB = await occurrenceRepo.listForOperator('operator-b');

      expect(forA.map((o) => o.id), ['occ-a-1']);
      expect(forB.map((o) => o.id), ['occ-b-1']);
      expect(await occurrenceRepo.listAll(), hasLength(3));
      expect(await occurrenceRepo.countOrphanOccurrences(), 1);
    });

    test('orphan occurrences are excluded from every operator list', () async {
      await occurrenceRepo.createOccurrence(
        id: 'legacy',
        title: 'Legada',
        description: 'd',
        status: 'draft',
        priority: 'medium',
        occurredAt: DateTime.utc(2026, 1, 1),
      );

      expect(await occurrenceRepo.listForOperator('operator-a'), isEmpty);
      expect(await occurrenceRepo.countOrphanOccurrences(), 1);
    });
  });

  group('CaptureOccurrenceService — reported_by stamp', () {
    test('captureDraft stamps reported_by with logged-in operator uid', () async {
      await configureDependenciesForTesting(
        db,
        authGateway: FakeAuthGateway(userId: 'uid-operator-a'),
        cameraSource: FakeCameraSource(),
        locationSource: FakeLocationSource(),
        hashService: FakeHashService(),
      );
      final captureService = getIt<CaptureOccurrenceService>();

      final draft = await captureService.captureDraft();
      final occurrence = await occurrenceRepo.getById(draft.occurrence.id);

      expect(occurrence!.reportedBy, 'uid-operator-a');
    });
  });

  group('SyncPayloadSerializer — reported_by', () {
    test('includes reported_by when occurrence has owner', () async {
      final occurrence = await occurrenceRepo.createOccurrence(
        id: 'occ-owned',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'medium',
        occurredAt: DateTime.utc(2026, 7, 8),
        reportedBy: 'operator-a',
      );

      final payload = serializer.serializeOccurrencesSyncPayload(
        items: [(occurrence: occurrence, media: const [])],
      );

      final json = (payload['occurrences'] as List).single as Map<String, dynamic>;
      expect(json['reported_by'], 'operator-a');
    });

    test('omits reported_by when occurrence is orphan (legacy)', () async {
      final occurrence = await occurrenceRepo.createOccurrence(
        id: 'occ-orphan',
        title: 'T',
        description: 'D',
        status: 'pending',
        priority: 'medium',
        occurredAt: DateTime.utc(2026, 7, 8),
      );

      final payload = serializer.serializeOccurrencesSyncPayload(
        items: [(occurrence: occurrence, media: const [])],
      );

      final json = (payload['occurrences'] as List).single as Map<String, dynamic>;
      expect(json.containsKey('reported_by'), isFalse);
    });
  });
}
