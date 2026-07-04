import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/core/messages/message_recipient_state.dart';
import 'package:sentinel_app/core/messages/message_type.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
import 'package:sentinel_app/data/repositories/message_repository.dart';

final messageTestConfig = AppConfig.fromMap({
  'SUPABASE_URL': 'http://localhost:54321',
  'SUPABASE_ANON_KEY': 'anon',
  'API_BASE_URL': 'http://localhost:8000/api/v1',
});

Map<String, dynamic> messageJson({
  required String id,
  String author = 'Coord',
  String title = 'Título',
  String body = 'Corpo',
  String type = MessageType.informe,
  String estado = MessageRecipientState.enviada,
  String createdAt = '2026-07-04T12:00:00Z',
  String? readAt,
  String? actedAt,
  bool portugueseFields = false,
}) {
  if (portugueseFields) {
    return {
      'id': id,
      'autor': author,
      'titulo': title,
      'corpo': body,
      'tipo': type,
      'estado': estado,
      'created_at': createdAt,
      if (readAt != null) 'read_at': readAt,
      if (actedAt != null) 'acted_at': actedAt,
    };
  }
  return {
    'id': id,
    'author': author,
    'title': title,
    'body': body,
    'type': type,
    'estado': estado,
    'created_at': createdAt,
    if (readAt != null) 'read_at': readAt,
    if (actedAt != null) 'acted_at': actedAt,
  };
}

http.Response messageListResponse(List<Map<String, dynamic>> items) {
  return http.Response(
    jsonEncode({'data': items}),
    200,
    headers: {'content-type': 'application/json'},
  );
}

http.Response messageActionResponse(Map<String, dynamic> item) {
  return http.Response(
    jsonEncode({'data': item}),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Future<void> seedCachedMessage(
  AppDatabase db, {
  required String id,
  String author = 'Coord',
  String title = 'Título',
  String body = 'Corpo',
  String type = MessageType.informe,
  String estado = MessageRecipientState.enviada,
  DateTime? createdAt,
}) async {
  await db.into(db.cachedMessages).insertOnConflictUpdate(
        CachedMessagesCompanion.insert(
          id: id,
          author: Value(author),
          title: Value(title),
          body: Value(body),
          type: type,
          estado: estado,
          createdAt: createdAt ?? DateTime.utc(2026, 7, 4, 12),
          cachedAt: DateTime.utc(2026, 7, 4, 12),
        ),
      );
}

MessageRepository messageRepositoryWithClient(
  AppDatabase db,
  MockClient client,
) {
  return MessageRepository(
    db,
    ApiClient(
      config: messageTestConfig,
      authGateway: FakeAuthGateway(),
      httpClient: client,
    ),
  );
}
