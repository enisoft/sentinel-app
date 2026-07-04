import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
import 'package:sentinel_app/data/repositories/operator_profile_repository.dart';

void main() {
  late AppDatabase db;

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

  test('fetchAndCache stores profile in drift', () async {
    final api = ApiClient(
      config: config,
      authGateway: FakeAuthGateway(),
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'user-1',
            'name': 'Operador Silva',
            'role': 'agente',
            'municipality_id': 'mun-1',
            'photo_path': 'avatars/x.jpg',
            'zones': [
              {'id': 'zona-1', 'nome': 'Manaus', 'tipo': 'municipio'},
            ],
            'default_zone_id': 'zona-1',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final repo = OperatorProfileRepository(db, api);
    final profile = await repo.fetchAndCache();

    expect(profile.name, 'Operador Silva');

    final cached = await repo.getCached();
    expect(cached?.id, 'user-1');
    expect(cached?.photoPath, 'avatars/x.jpg');
    expect(cached?.zones, hasLength(1));
    expect(cached?.zones.single.nome, 'Manaus');
    expect(cached?.defaultZoneId, 'zona-1');
  });
}
