import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
import 'package:sentinel_app/data/services/catalog_sync_service.dart';

void main() {
  late AppDatabase db;
  late CatalogSyncService service;

  final config = AppConfig.fromMap({
    'SUPABASE_URL': 'http://localhost:54321',
    'SUPABASE_ANON_KEY': 'anon',
    'API_BASE_URL': 'http://localhost:8000/api/v1',
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ApiClient buildClient(MockClientHandler handler) {
    return ApiClient(
      config: config,
      authGateway: FakeAuthGateway(),
      httpClient: MockClient(handler),
    );
  }

  test('full snapshot upserts items and stores server_time cursor', () async {
    service = CatalogSyncService(
      db,
      buildClient((request) async {
        return http.Response(
          jsonEncode({
            'updated_since': null,
            'server_time': '2026-06-12T10:00:00Z',
            'items': [
              {'id': 'obs-1', 'type': 'person', 'name': 'A'},
            ],
            'deleted_ids': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await service.syncObservables();

    final rows = await db.select(db.observables).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'A');

    final cursor = await (db.select(db.catalogSyncCursors)
          ..where((t) => t.entity.equals('observables')))
        .getSingle();
    expect(cursor.lastServerTime, '2026-06-12T10:00:00Z');
  });

  test('delta applies deleted_ids locally', () async {
    await db.into(db.observables).insert(
          ObservablesCompanion.insert(
            id: 'obs-old',
            type: 'person',
            name: 'Old',
            updatedAt: DateTime.utc(2026, 6, 1),
          ),
        );

    await db.into(db.catalogSyncCursors).insert(
          CatalogSyncCursorsCompanion.insert(
            entity: 'observables',
            lastServerTime: const Value('2026-06-01T00:00:00Z'),
          ),
        );

    service = CatalogSyncService(
      db,
      buildClient((request) async {
        expect(request.url.queryParameters['updated_since'], '2026-06-01T00:00:00Z');
        return http.Response(
          jsonEncode({
            'updated_since': '2026-06-01T00:00:00Z',
            'server_time': '2026-06-12T10:00:00Z',
            'items': [],
            'deleted_ids': ['obs-old'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await service.syncObservables();

    final rows = await db.select(db.observables).get();
    expect(rows, isEmpty);

    final cursor = await (db.select(db.catalogSyncCursors)
          ..where((t) => t.entity.equals('observables')))
        .getSingle();
    expect(cursor.lastServerTime, '2026-06-12T10:00:00Z');
  });

  test('zones full snapshot upserts items and stores cursor', () async {
    service = CatalogSyncService(
      db,
      buildClient((request) async {
        return http.Response(
          jsonEncode({
            'updated_since': null,
            'server_time': '2026-07-04T10:00:00Z',
            'items': [
              {
                'id': 'zone-1',
                'nome': 'Manaus',
                'tipo': 'municipio',
                'municipio_pai_id': null,
              },
            ],
            'deleted_ids': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await service.syncZones();

    final rows = await db.select(db.catalogZones).get();
    expect(rows, hasLength(1));
    expect(rows.single.nome, 'Manaus');
    expect(rows.single.tipo, 'municipio');

    final cursor = await (db.select(db.catalogSyncCursors)
          ..where((t) => t.entity.equals('zones')))
        .getSingle();
    expect(cursor.lastServerTime, '2026-07-04T10:00:00Z');
  });

  test('zones delta applies deleted_ids locally', () async {
    await db.into(db.catalogZones).insert(
          CatalogZonesCompanion.insert(
            id: 'zone-old',
            nome: 'Antiga',
            tipo: 'bairro',
            updatedAt: DateTime.utc(2026, 6, 1),
          ),
        );

    await db.into(db.catalogSyncCursors).insert(
          CatalogSyncCursorsCompanion.insert(
            entity: 'zones',
            lastServerTime: const Value('2026-06-01T00:00:00Z'),
          ),
        );

    service = CatalogSyncService(
      db,
      buildClient((request) async {
        expect(request.url.path, endsWith('/catalog/zones'));
        return http.Response(
          jsonEncode({
            'updated_since': '2026-06-01T00:00:00Z',
            'server_time': '2026-07-04T10:00:00Z',
            'items': [],
            'deleted_ids': ['zone-old'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await service.syncZones();

    final rows = await db.select(db.catalogZones).get();
    expect(rows, isEmpty);
  });
}
