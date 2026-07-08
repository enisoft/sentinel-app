import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_camera_source.dart';
import 'package:sentinel_app/data/fakes/fake_hash_service.dart';
import 'package:sentinel_app/data/fakes/fake_location_source.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/catalog_repository.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/operator_profile_repository.dart';
import 'package:sentinel_app/data/services/capture_occurrence_service.dart';
import 'package:sentinel_app/data/sync/sync_payload_serializer.dart';
import 'package:sentinel_app/domain/models/operator_zone.dart';
import 'package:sentinel_app/presentation/capture/occurrence_draft_form_screen.dart';

void main() {
  late AppDatabase db;
  late CaptureOccurrenceService captureService;
  late OccurrenceRepository occurrenceRepo;
  late CatalogRepository catalogRepo;
  late OperatorProfileRepository profileRepo;

  const zoneDefault = OperatorZone(
    id: 'zone-default',
    nome: 'Manaus',
    tipo: 'municipio',
  );
  const zoneOther = OperatorZone(
    id: 'zone-other',
    nome: 'Iracema',
    tipo: 'bairro',
  );

  Future<void> seedProfile({
    required List<OperatorZone> zones,
    String? defaultZoneId,
  }) async {
    await db.into(db.cachedOperatorProfiles).insertOnConflictUpdate(
          CachedOperatorProfilesCompanion.insert(
            id: 'test-operator-uid',
            name: 'Operador',
            role: 'agente',
            municipalityId: const Value('mun-1'),
            zonesJson: Value(
              '[${zones.map((z) => '{"id":"${z.id}","nome":"${z.nome}","tipo":"${z.tipo}"}').join(',')}]',
            ),
            defaultZoneId: Value(defaultZoneId),
            cachedAt: DateTime.utc(2026, 7, 4),
          ),
        );
  }

  Future<String> createDraft() async {
    final draft = await captureService.captureDraft();
    return draft.occurrence.id;
  }

  Future<void> pumpForm(WidgetTester tester, String occurrenceId) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OccurrenceDraftFormScreen(
          occurrenceId: occurrenceId,
          captureService: captureService,
          catalogRepository: catalogRepo,
          operatorProfileRepository: profileRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await configureDependenciesForTesting(
      db,
      authGateway: FakeAuthGateway(),
      cameraSource: FakeCameraSource(),
      locationSource: FakeLocationSource(),
      hashService: FakeHashService(),
    );
    captureService = getIt<CaptureOccurrenceService>();
    occurrenceRepo = getIt<OccurrenceRepository>();
    catalogRepo = getIt<CatalogRepository>();
    profileRepo = getIt<OperatorProfileRepository>();

    await catalogRepo.seedForTesting(
      categories: const [CatalogItem(id: 'cat-1', name: 'Evento')],
      observables: const [
        CatalogItem(id: 'obs-1', name: 'Político', type: 'person'),
      ],
    );
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  testWidgets('pre-selects default zone from cached profile', (tester) async {
    await seedProfile(
      zones: const [zoneDefault, zoneOther],
      defaultZoneId: 'zone-default',
    );
    final occurrenceId = await createDraft();
    await pumpForm(tester, occurrenceId);

    expect(find.text('Manaus'), findsOneWidget);
    final occurrence = await occurrenceRepo.getById(occurrenceId);
    expect(occurrence!.zonaId, 'zone-default');
  });

  testWidgets('switching zone persists zona_id on draft', (tester) async {
    await seedProfile(
      zones: const [zoneDefault, zoneOther],
      defaultZoneId: 'zone-default',
    );
    final occurrenceId = await createDraft();
    await pumpForm(tester, occurrenceId);

    await tester.tap(find.byKey(const Key('zone_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iracema').last);
    await tester.pumpAndSettle();

    final occurrence = await occurrenceRepo.getById(occurrenceId);
    expect(occurrence!.zonaId, 'zone-other');
  });

  testWidgets('single zone is locked and pre-selected', (tester) async {
    await seedProfile(
      zones: const [zoneDefault],
      defaultZoneId: 'zone-default',
    );
    final occurrenceId = await createDraft();
    await pumpForm(tester, occurrenceId);

    final dropdown =
        tester.widget<DropdownButtonFormField<String>>(find.byKey(const Key('zone_field')));
    expect(dropdown.onChanged, isNull);

    final occurrence = await occurrenceRepo.getById(occurrenceId);
    expect(occurrence!.zonaId, 'zone-default');
  });

  testWidgets('confirm includes chosen zona_id in sync payload', (tester) async {
    await seedProfile(
      zones: const [zoneDefault, zoneOther],
      defaultZoneId: 'zone-default',
    );
    final occurrenceId = await createDraft();
    await pumpForm(tester, occurrenceId);

    await tester.tap(find.byKey(const Key('zone_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iracema').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('category_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evento').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_button')));
    await tester.pumpAndSettle();

    final occurrence = await occurrenceRepo.getById(occurrenceId);
    expect(occurrence!.status, 'pending');
    expect(occurrence.zonaId, 'zone-other');

    const serializer = SyncPayloadSerializer();
    final media = await occurrenceRepo.getMedia(occurrenceId);
    final payload = serializer.serializeOccurrencesSyncPayload(
      items: [(occurrence: occurrence, media: media)],
    );
    final json = (payload['occurrences'] as List).single as Map<String, dynamic>;
    expect(json['zona_id'], 'zone-other');
  });
}
