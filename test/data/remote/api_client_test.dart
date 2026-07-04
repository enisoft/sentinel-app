import 'dart:convert';
import 'dart:io';

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

    test('request timeout throws ApiException 408', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        requestTimeout: const Duration(milliseconds: 50),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return http.Response('', 200);
        }),
      );

      expect(
        () => client.getMe(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 408)
              .having((e) => e.isNetworkError, 'isNetworkError', isTrue)
              .having((e) => e.message, 'message', contains('Tempo esgotado')),
        ),
      );
    });

    test('socket failure throws network ApiException', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((_) async {
          throw const SocketException('Network is unreachable');
        }),
      );

      expect(
        () => client.getMe(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetworkError, 'isNetworkError', isTrue)
              .having((e) => e.isUnauthorized, 'isUnauthorized', isFalse),
        ),
      );
    });

    test('client exception throws network ApiException', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((_) async {
          throw http.ClientException('Connection refused');
        }),
      );

      expect(
        () => client.getMe(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetworkError, 'isNetworkError', isTrue)
              .having((e) => e.isUnauthorized, 'isUnauthorized', isFalse),
        ),
      );
    });

    test('postOccurrencesSync sends JSON and parses data.ids', () async {
      Map<String, dynamic>? capturedBody;

      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(token: 'jwt-sync'),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/occurrences/sync');
          expect(request.headers['Authorization'], 'Bearer jwt-sync');
          expect(request.headers['Content-Type'], 'application/json');
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'message': 'Ocorrências sincronizadas com sucesso.',
              'data': {
                'synced_count': 1,
                'created_count': 1,
                'updated_count': 0,
                'ids': ['occ-1'],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final ids = await client.postOccurrencesSync({
        'occurrences': [
          {'id': 'occ-1', 'title': 'T', 'description': 'D'},
        ],
      });

      expect(ids, ['occ-1']);
      expect(capturedBody?['occurrences'], isNotNull);
      final occurrence = (capturedBody!['occurrences'] as List).single
          as Map<String, dynamic>;
      expect(occurrence.containsKey('reported_by'), isFalse);
    });

    test('postOccurrencesSync 401 throws ApiException', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({'message': 'Token de autenticação inválido.'}),
            401,
          );
        }),
      );

      expect(
        () => client.postOccurrencesSync({'occurrences': []}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue),
        ),
      );
    });

    test('postOccurrencesSync 422 throws validation ApiException', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({'message': 'title é obrigatório.'}),
            422,
          );
        }),
      );

      expect(
        () => client.postOccurrencesSync({'occurrences': []}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isValidation, 'isValidation', isTrue),
        ),
      );
    });

    test('postOccurrencesSync 500 throws server ApiException', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({'message': 'Erro interno.'}),
            500,
          );
        }),
      );

      expect(
        () => client.postOccurrencesSync({'occurrences': []}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isServerError, 'isServerError', isTrue)
              .having((e) => e.isRetryable, 'isRetryable', isTrue),
        ),
      );
    });

    test('getMessages parses inbox list with Portuguese fields', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(token: 'jwt-1'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/messages');
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'rec-1',
                  'estado': 'enviada',
                  'message': {
                    'id': 'msg-1',
                    'titulo': 'Aviso',
                    'corpo': 'Corpo',
                    'tipo': 'informe',
                    'autor': 'Coordenador',
                    'created_at': '2026-07-04T12:00:00Z',
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final items = await client.getMessages();
      expect(items, hasLength(1));
      expect(items.single.id, 'msg-1');
      expect(items.single.title, 'Aviso');
      expect(items.single.body, 'Corpo');
    });

    test('getMessages parses inbox list', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(token: 'jwt-1'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/messages');
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'msg-1',
                  'author': 'Coordenador',
                  'title': 'Aviso',
                  'body': 'Corpo',
                  'type': 'informe',
                  'estado': 'enviada',
                  'created_at': '2026-07-04T12:00:00Z',
                },
                {
                  'id': 'msg-2',
                  'author': 'Coordenador',
                  'title': 'Patrulha',
                  'body': 'Ir ao ponto X',
                  'type': 'tarefa',
                  'estado': 'lida',
                  'created_at': '2026-07-03T10:00:00Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final items = await client.getMessages();
      expect(items, hasLength(2));
      expect(items.first.id, 'msg-1');
      expect(items.last.isTarefa, isTrue);
    });

    test('postMessageRead parses updated message', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/messages/msg-1/read');
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'msg-1',
                'author': 'Coord',
                'title': 'T',
                'body': 'B',
                'type': 'informe',
                'estado': 'lida',
                'created_at': '2026-07-04T12:00:00Z',
                'read_at': '2026-07-04T13:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final updated = await client.postMessageRead('msg-1');
      expect(updated.estado, 'lida');
      expect(updated.readAt, isNotNull);
    });

    test('postMessageAccept posts to accept endpoint', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/messages/task-1/accept');
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'task-1',
                'author': 'Coord',
                'title': 'Tarefa',
                'body': 'Fazer X',
                'type': 'tarefa',
                'estado': 'aceita',
                'created_at': '2026-07-04T12:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final updated = await client.postMessageAccept('task-1');
      expect(updated.estado, 'aceita');
      expect(updated.isTarefa, isTrue);
    });

    test('postMessageComplete posts to complete endpoint', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/messages/task-1/complete');
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'task-1',
                'type': 'tarefa',
                'estado': 'concluida',
                'created_at': '2026-07-04T12:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      expect((await client.postMessageComplete('task-1')).estado, 'concluida');
    });

    test('postMessageReject posts to reject endpoint', () async {
      final client = ApiClient(
        config: config,
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/messages/task-1/reject');
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'task-1',
                'type': 'tarefa',
                'estado': 'recusada',
                'created_at': '2026-07-04T12:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      expect((await client.postMessageReject('task-1')).estado, 'recusada');
    });
  });
}
