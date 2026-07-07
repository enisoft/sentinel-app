import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_network_reachability.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
import 'package:sentinel_app/presentation/auth/auth_gate.dart';

void main() {
  late AppDatabase db;
  late FakeAuthGateway auth;
  late FakeNetworkReachability network;

  final config = AppConfig.fromMap({
    'SUPABASE_URL': 'http://localhost:54321',
    'SUPABASE_ANON_KEY': 'anon',
    'API_BASE_URL': 'http://localhost:8000/api/v1',
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    network = FakeNetworkReachability(online: false);
    auth = FakeAuthGateway(
      signedIn: true,
      persistedSession: true,
      networkReachability: network,
    );
  });

  tearDown(() async {
    auth.dispose();
    await getIt.reset();
    await db.close();
  });

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

  Future<void> pumpAuthGate(WidgetTester tester) async {
    await configureDependenciesForTesting(
      db,
      authGateway: auth,
      apiClient: ApiClient(
        config: config,
        authGateway: auth,
        httpClient: MockClient((request) async {
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
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: AuthGate(authGateway: auth)),
    );
  }

  testWidgets(
    'sessionStream null with persisted session stays in app (ENI-84)',
    (tester) async {
      await seedCachedProfile();
      auth.refreshSucceeds = false;
      auth.simulateOfflineSessionLoss();

      await pumpAuthGate(tester);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(auth.isSignedIn, isFalse);
      expect(auth.canAccessApp, isTrue);
      expect(await auth.hasPersistedSession(), isTrue);
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
      expect(find.byKey(const Key('login_submit')), findsNothing);
    },
  );

  testWidgets('401 online still signs out (ENI-84)', (tester) async {
    network.online = true;
    auth.refreshSucceeds = false;

    await configureDependenciesForTesting(
      db,
      authGateway: auth,
      apiClient: ApiClient(
        config: config,
        authGateway: auth,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/me')) {
            return http.Response(
              jsonEncode({'message': 'Token de autenticação inválido.'}),
              401,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('', 404);
        }),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: AuthGate(authGateway: auth)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(auth.canAccessApp, isFalse);
    expect(find.text('Sessão expirada, faça login de novo.'), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  testWidgets('reconnect refresh keeps operator in app (ENI-84)', (tester) async {
    await seedCachedProfile();
    auth.refreshSucceeds = true;
    auth.simulateOfflineSessionLoss();

    await pumpAuthGate(tester);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(auth.canAccessApp, isTrue);
    expect(find.byKey(const Key('home_screen')), findsOneWidget);
  });
}
