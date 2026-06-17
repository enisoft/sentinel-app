import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
import 'package:sentinel_app/data/remote/api_exception.dart';
import 'package:sentinel_app/data/remote/catalog_delta_response.dart';

void main() {
  final config = AppConfig.fromMap({
    'SUPABASE_URL': 'http://localhost:54321',
    'SUPABASE_ANON_KEY': 'anon',
    'API_BASE_URL': 'http://localhost:8000/api/v1',
  });

  group('ApiClient', () {
    test('getMe parses operator profile', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(token: 'jwt-1'),
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer jwt-1');
          return http.Response(
            jsonEncode({
              'id': 'user-1',
              'name': 'Operador',
              'role': 'agente',
              'municipality_id': 'mun-1',
              'photo_path': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final profile = await client.getMe();
      expect(profile.id, 'user-1');
      expect(profile.name, 'Operador');
      expect(profile.role, 'agente');
      expect(profile.municipalityId, 'mun-1');
    });

    test('getCatalogObservables parses delta response', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['updated_since'], '2026-06-01T00:00:00Z');
          return http.Response(
            jsonEncode({
              'updated_since': '2026-06-01T00:00:00Z',
              'server_time': '2026-06-12T10:00:00Z',
              'items': [
                {'id': 'obs-1', 'type': 'person', 'name': 'Test'},
              ],
              'deleted_ids': ['obs-old'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final delta = await client.getCatalogObservables(
        updatedSince: '2026-06-01T00:00:00Z',
      );

      expect(delta, isA<CatalogDeltaResponse>());
      expect(delta.serverTime, '2026-06-12T10:00:00Z');
      expect(delta.items, hasLength(1));
      expect(delta.deletedIds, ['obs-old']);
    });

    test('401 throws ApiException', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'message': 'Token de autenticação inválido.'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      expect(
        () => client.getMe(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue),
        ),
      );
    });

    test('missing token throws 401 ApiException', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(signedIn: false),
        httpClient: MockClient((_) async => http.Response('', 200)),
      );

      expect(
        () => client.getMe(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    });
  });
}
