import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/core/bootstrap/bootstrap_messages.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
import 'package:sentinel_app/data/remote/api_exception.dart';
import 'package:sentinel_app/data/repositories/operator_profile_repository.dart';
import 'package:sentinel_app/data/services/bootstrap_service.dart';
import 'package:sentinel_app/data/services/catalog_sync_service.dart';

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

  BootstrapService buildService(http.Client httpClient) {
    final api = ApiClient(
      config: config,
      authGateway: FakeAuthGateway(),
      httpClient: httpClient,
    );
    return BootstrapService(
      OperatorProfileRepository(db, api, FakeAuthGateway(userId: 'user-1')),
      CatalogSyncService(db, api),
    );
  }

  Future<void> seedCachedProfile() async {
    await db.into(db.cachedOperatorProfiles).insertOnConflictUpdate(
          CachedOperatorProfilesCompanion.insert(
            id: 'user-1',
            name: 'Operador',
            role: 'agente',
            municipalityId: const Value('mun-1'),
            photoPath: const Value(null),
            cachedAt: DateTime.utc(2026, 6, 18),
          ),
        );
  }

  test('network error on /me with cached profile enters app', () async {
    await seedCachedProfile();

    final service = buildService(
      MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          throw const SocketException('Network is unreachable');
        }
        return http.Response('', 404);
      }),
    );

    final result = await service.run();

    expect(result.profileLoaded, isTrue);
    expect(result.catalogSynced, isFalse);
  });

  test('401 on /me propagates for signOut', () async {
    final service = buildService(
      MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            jsonEncode({'message': 'Token de autenticação inválido.'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 404);
      }),
    );

    expect(
      () => service.run(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue),
      ),
    );
  });

  test('network error without cached profile shows first-access message', () async {
    final service = buildService(
      MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          throw http.ClientException('Connection refused');
        }
        return http.Response('', 404);
      }),
    );

    final result = await service.run();

    expect(result.profileLoaded, isFalse);
    expect(result.catalogError, BootstrapMessages.offlineFirstAccess);
  });
}
