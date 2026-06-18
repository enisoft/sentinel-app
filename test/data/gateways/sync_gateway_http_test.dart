import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/gateways/sync_gateway_http.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;

  final config = AppConfig.fromMap({
    'SUPABASE_URL': 'http://localhost:54321',
    'SUPABASE_ANON_KEY': 'anon',
    'API_BASE_URL': 'http://localhost:8000/api/v1',
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('syncOccurrences posts serialized payload matching contract', () async {
    final occurredAt = DateTime.utc(2026, 6, 10, 14, 30);
    final createdAt = DateTime.utc(2026, 6, 10, 14, 35);

    await occurrenceRepo.createOccurrence(
      id: '550e8400-e29b-41d4-a716-446655440000',
      title: 'Vazamento no corredor',
      description: 'Água acumulada próximo ao elevador.',
      status: 'pending',
      priority: 'high',
      occurredAt: occurredAt,
      createdAt: createdAt,
      updatedAt: createdAt,
      createdLocalAt: DateTime.utc(2026, 6, 10, 14, 36),
    );

    await occurrenceRepo.attachMedia(
      id: '8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00',
      occurrenceId: '550e8400-e29b-41d4-a716-446655440000',
      mediaType: 'image',
      localPath: '/tmp/foto.jpg',
      remotePath: 'occurrences/550e8400/photo1.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 245760,
    );

    Map<String, dynamic>? capturedBody;

    final apiClient = ApiClient(
      config: config,
      authGateway: FakeAuthGateway(token: 'jwt-1'),
      httpClient: MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'data': {
              'ids': ['550e8400-e29b-41d4-a716-446655440000'],
            },
          }),
          200,
        );
      }),
    );

    final gateway = SyncGatewayHttp(
      apiClient: apiClient,
      occurrenceRepository: occurrenceRepo,
    );

    final ids = await gateway.syncOccurrences(
      occurrenceIds: ['550e8400-e29b-41d4-a716-446655440000'],
    );

    expect(ids, ['550e8400-e29b-41d4-a716-446655440000']);
    expect(capturedBody?['occurrences'], hasLength(1));

    final json = (capturedBody!['occurrences'] as List).single
        as Map<String, dynamic>;
    expect(json['id'], '550e8400-e29b-41d4-a716-446655440000');
    expect(json.containsKey('reported_by'), isFalse);
    expect(
      (json['media'] as List).single,
      containsPair('path', 'occurrences/550e8400/photo1.jpg'),
    );
  });
}
