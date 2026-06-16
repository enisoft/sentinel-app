import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/check_in_repository.dart';
import 'package:sentinel_app/data/sync/sync_payload_serializer.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  late CheckInRepository checkInRepo;
  const serializer = SyncPayloadSerializer();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
    checkInRepo = CheckInRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncPayloadSerializer — occurrences', () {
    test('serializes occurrence with 2 media matching sync contract', () async {
      final occurredAt = DateTime.utc(2026, 6, 10, 14, 30);
      final createdAt = DateTime.utc(2026, 6, 10, 14, 35);
      final updatedAt = DateTime.utc(2026, 6, 10, 14, 35);

      final occurrence = await occurrenceRepo.createOccurrence(
        id: '550e8400-e29b-41d4-a716-446655440000',
        observableId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        categoryId: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        title: 'Vazamento no corredor',
        description: 'Água acumulada próximo ao elevador.',
        status: 'pending',
        priority: 'high',
        location: 'Bloco A - 2º andar',
        latitude: -25.5284,
        longitude: -49.1758,
        occurredAt: occurredAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdLocalAt: DateTime.utc(2026, 6, 10, 14, 36),
      );

      await occurrenceRepo.attachMedia(
        id: '8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00',
        occurrenceId: occurrence.id,
        mediaType: 'image',
        localPath: '/tmp/foto_corredor.jpg',
        remotePath: 'occurrences/550e8400/photo1.jpg',
        mimeType: 'image/jpeg',
        originalName: 'foto_corredor.jpg',
        sizeBytes: 245760,
        sortOrder: 0,
      );
      await occurrenceRepo.attachMedia(
        id: '9a25f560-dffb-5780-b1a9-6d4c3f2b0e11',
        occurrenceId: occurrence.id,
        mediaType: 'audio',
        localPath: '/tmp/nota_voz.m4a',
        remotePath: 'occurrences/550e8400/nota_voz.m4a',
        mimeType: 'audio/mp4',
        originalName: 'nota_voz.m4a',
        sizeBytes: 512000,
        sortOrder: 1,
        durationSeconds: 32,
      );

      final media = await occurrenceRepo.getMedia(occurrence.id);
      final payload = serializer.serializeOccurrencesSyncPayload(
        items: [(occurrence: occurrence, media: media)],
      );

      expect(payload.keys, ['occurrences']);
      final occurrences = payload['occurrences'] as List<dynamic>;
      expect(occurrences, hasLength(1));

      final json = occurrences.single as Map<String, dynamic>;
      expect(json, {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'observable_id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'category_id': 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        'title': 'Vazamento no corredor',
        'description': 'Água acumulada próximo ao elevador.',
        'status': 'pending',
        'priority': 'high',
        'location': 'Bloco A - 2º andar',
        'latitude': -25.5284,
        'longitude': -49.1758,
        'occurred_at': '2026-06-10T14:30:00Z',
        'resolved_at': null,
        'created_at': '2026-06-10T14:35:00Z',
        'updated_at': '2026-06-10T14:35:00Z',
        'media': [
          {
            'id': '8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00',
            'media_type': 'image',
            'path': 'occurrences/550e8400/photo1.jpg',
            'mime_type': 'image/jpeg',
            'original_name': 'foto_corredor.jpg',
            'size_bytes': 245760,
            'sort_order': 0,
            'duration_seconds': null,
          },
          {
            'id': '9a25f560-dffb-5780-b1a9-6d4c3f2b0e11',
            'media_type': 'audio',
            'path': 'occurrences/550e8400/nota_voz.m4a',
            'mime_type': 'audio/mp4',
            'original_name': 'nota_voz.m4a',
            'size_bytes': 512000,
            'sort_order': 1,
            'duration_seconds': 32,
          },
        ],
      });

      expect(json.containsKey('reported_by'), isFalse);
      expect(json.containsKey('assigned_to'), isFalse);
      expect(json.containsKey('synced_at'), isFalse);
      expect(json.containsKey('created_local_at'), isFalse);
      expect(json.containsKey('sync_state'), isFalse);

      final mediaJson = json['media'] as List<dynamic>;
      for (final item in mediaJson) {
        final m = item as Map<String, dynamic>;
        expect(m.containsKey('local_path'), isFalse);
        expect(m.containsKey('remote_path'), isFalse);
        expect(m.containsKey('path'), isTrue);
      }
    });
  });

  group('SyncPayloadSerializer — check-ins', () {
    test('serializes check-in matching P4 sync contract', () async {
      final checkIn = await checkInRepo.createCheckIn(
        id: 'ci-uuid-1',
        latitude: -3.1,
        longitude: -60.0,
        accuracy: 8.5,
        capturedAt: DateTime.utc(2026, 6, 12, 9, 0),
      );

      final payload = serializer.serializeCheckInsSyncPayload(checkIns: [checkIn]);

      expect(payload, {
        'check_ins': [
          {
            'id': 'ci-uuid-1',
            'latitude': -3.1,
            'longitude': -60.0,
            'accuracy': 8.5,
            'captured_at': '2026-06-12T09:00:00Z',
            'note': null,
          },
        ],
      });

      final json = (payload['check_ins'] as List<dynamic>).single
          as Map<String, dynamic>;
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('synced_at'), isFalse);
      expect(json.containsKey('created_local_at'), isFalse);
      expect(json.containsKey('sync_state'), isFalse);
      expect(json.containsKey('media_uploaded_at'), isFalse);
    });
  });
}
