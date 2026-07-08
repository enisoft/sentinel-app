import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/auth/auth_messages.dart';
import 'package:sentinel_app/core/bootstrap/bootstrap_messages.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_network_reachability.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/presentation/auth/auth_gate.dart';
import '../../support/counting_occurrence_sync_foreground_runner.dart';

void main() {
  late AppDatabase db;
  late FakeAuthGateway auth;

  final config = AppConfig.fromMap({
    'SUPABASE_URL': 'http://localhost:54321',
    'SUPABASE_ANON_KEY': 'anon',
    'API_BASE_URL': 'http://localhost:8000/api/v1',
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    auth = FakeAuthGateway(
      signedIn: true,
      networkReachability: FakeNetworkReachability(online: true),
    );
  });

  tearDown(() async {
    auth.dispose();
    await getIt.reset();
    await db.close();
  });

  Future<void> pumpAuthGate(WidgetTester tester, http.Client httpClient) async {
    await configureDependenciesForTesting(
      db,
      authGateway: auth,
      apiClient: ApiClient(
        config: config,
        authGateway: auth,
        httpClient: httpClient,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: AuthGate(authGateway: auth)),
    );
  }

  Future<void> seedCachedProfile() async {
    await db.into(db.cachedOperatorProfiles).insertOnConflictUpdate(
          CachedOperatorProfilesCompanion.insert(
            id: 'test-operator-uid',
            name: 'Operador',
            role: 'agente',
            municipalityId: const Value('mun-1'),
            photoPath: const Value(null),
            cachedAt: DateTime.utc(2026, 6, 18),
          ),
        );
  }

  testWidgets('network error on /me with cached profile stays signed in',
      (tester) async {
    await seedCachedProfile();

    await pumpAuthGate(
      tester,
      MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/me')) {
          throw const SocketException('Network is unreachable');
        }
        if (path.contains('/catalog/')) {
          throw http.ClientException('Connection refused');
        }
        if (path.endsWith('/messages')) {
          return http.Response(
            jsonEncode({'data': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 404);
      }),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(auth.isSignedIn, isTrue);
    expect(find.byKey(const Key('home_screen')), findsOneWidget);
    expect(find.byKey(const Key('add_occurrence_fab')), findsOneWidget);
    expect(find.byKey(const Key('capture_button')), findsNothing);
    expect(find.text('Sincronizando...'), findsNothing);
    expect(find.byKey(const Key('login_submit')), findsNothing);
  });

  testWidgets('network error without cached profile shows offline first access',
      (tester) async {
    await pumpAuthGate(
      tester,
      MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          throw const SocketException('Network is unreachable');
        }
        return http.Response('', 404);
      }),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(auth.isSignedIn, isTrue);
    expect(find.text(BootstrapMessages.offlineFirstAccess), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsNothing);
  });

  testWidgets('401 on /me ends loading and shows session expired on login',
      (tester) async {
    auth.refreshSucceeds = false;

    await pumpAuthGate(
      tester,
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

    await tester.pump();
    await tester.pumpAndSettle();

    expect(auth.isSignedIn, isFalse);
    expect(find.text(AuthMessages.sessionExpired), findsOneWidget);
    expect(find.text('Sincronizando...'), findsNothing);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  Future<void> seedPendingOccurrence() async {
    final occurrenceRepo = OccurrenceRepository(db);
    await occurrenceRepo.createOccurrence(
      id: 'pending-bootstrap',
      title: 'Test',
      description: 'Desc',
      status: 'pending',
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 1),
      reportedBy: 'test-operator-uid',
    );
  }

  testWidgets('bootstrap does not call runIfPending automatically', (tester) async {
    await configureDependenciesForTesting(
      db,
      authGateway: auth,
      apiClient: ApiClient(
        config: config,
        authGateway: auth,
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/me')) {
            return http.Response(
              jsonEncode({
                'id': 'test-operator-uid',
                'name': 'Operador',
                'role': 'agente',
                'municipality_id': 'mun-1',
                'photo_path': null,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (path.contains('/catalog/')) {
            return http.Response(
              jsonEncode({
                'updated_since': null,
                'server_time': '2026-06-17T00:00:00Z',
                'items': [],
                'deleted_ids': [],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (path.endsWith('/messages')) {
            return http.Response(
              jsonEncode({'data': []}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('', 404);
        }),
      ),
    );

    final countingRunner = installCountingForegroundRunner();
    await seedPendingOccurrence();

    await tester.pumpWidget(
      MaterialApp(home: AuthGate(authGateway: auth)),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(countingRunner.runIfPendingCallCount, 0);
    expect(find.byKey(const Key('home_screen')), findsOneWidget);
    expect(find.byKey(const Key('add_occurrence_fab')), findsOneWidget);
    expect(find.byKey(const Key('capture_button')), findsNothing);
    expect(find.byKey(const Key('pending_sync_badge')), findsOneWidget);
    expect(find.text('1 pendente(s)'), findsOneWidget);
  });

  testWidgets('successful bootstrap reaches home occurrences tab', (tester) async {
    await pumpAuthGate(
      tester,
      MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/me')) {
          return http.Response(
            jsonEncode({
              'id': 'test-operator-uid',
              'name': 'Operador',
              'role': 'agente',
              'municipality_id': 'mun-1',
              'photo_path': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/catalog/')) {
          return http.Response(
            jsonEncode({
              'updated_since': null,
              'server_time': '2026-06-17T00:00:00Z',
              'items': [],
              'deleted_ids': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.endsWith('/messages')) {
          return http.Response(
            jsonEncode({'data': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 404);
      }),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(auth.isSignedIn, isTrue);
    expect(find.byKey(const Key('home_screen')), findsOneWidget);
    expect(find.byKey(const Key('add_occurrence_fab')), findsOneWidget);
    expect(find.byKey(const Key('capture_button')), findsNothing);
    expect(find.text('Sincronizando...'), findsNothing);
  });
}
