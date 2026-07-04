import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/core/messages/message_recipient_state.dart';
import 'package:sentinel_app/core/messages/message_type.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/message_repository.dart';

import '../../support/message_test_helpers.dart';

void main() {
  late AppDatabase db;
  late MessageRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        if (request.url.path.endsWith('/messages') && request.method == 'GET') {
          return messageListResponse([
            messageJson(id: 'msg-1', title: 'Nova'),
            messageJson(
              id: 'msg-2',
              title: 'Tarefa',
              type: MessageType.tarefa,
              estado: MessageRecipientState.lida,
              createdAt: '2026-07-03T10:00:00Z',
            ),
          ]);
        }
        return http.Response('not found', 404);
      }),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('refresh caches messages ordered by createdAt desc', () async {
    await repository.refresh();

    final items = await repository.listAll();
    expect(items, hasLength(2));
    expect(items.first.id, 'msg-1');
    expect(items.last.id, 'msg-2');
  });

  test('refresh replaces previous cache snapshot', () async {
    await repository.refresh();
    expect(await repository.listAll(), hasLength(2));

    final emptyRepository = messageRepositoryWithClient(
      db,
      MockClient((request) async => messageListResponse([])),
    );
    await emptyRepository.refresh();

    expect(await emptyRepository.listAll(), isEmpty);
    expect(emptyRepository.unreadCount.value, 0);
  });

  test('unreadCount tracks enviada only', () async {
    await repository.refresh();
    expect(repository.unreadCount.value, 1);
  });

  test('markRead updates local cache and unreadCount', () async {
    await repository.refresh();

    final readRepository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        return messageActionResponse(
          messageJson(
            id: 'msg-1',
            estado: MessageRecipientState.lida,
            readAt: '2026-07-04T13:00:00Z',
          ),
        );
      }),
    );

    final updated = await readRepository.markRead('msg-1');
    expect(updated.estado, MessageRecipientState.lida);
    expect((await readRepository.getById('msg-1'))!.estado,
        MessageRecipientState.lida);
    expect(readRepository.unreadCount.value, 0);
  });

  test('accept updates local cache', () async {
    await seedCachedMessage(
      db,
      id: 'task-1',
      type: MessageType.tarefa,
      estado: MessageRecipientState.lida,
    );

    final acceptRepository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        expect(request.url.path, '/api/v1/messages/task-1/accept');
        return messageActionResponse(
          messageJson(
            id: 'task-1',
            type: MessageType.tarefa,
            estado: MessageRecipientState.aceita,
            actedAt: '2026-07-04T15:00:00Z',
          ),
        );
      }),
    );

    final updated = await acceptRepository.accept('task-1');
    expect(updated.estado, MessageRecipientState.aceita);
    expect((await acceptRepository.getById('task-1'))!.estado,
        MessageRecipientState.aceita);
  });

  test('reject updates local cache', () async {
    await seedCachedMessage(
      db,
      id: 'task-2',
      type: MessageType.tarefa,
      estado: MessageRecipientState.lida,
    );

    final rejectRepository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        expect(request.url.path, '/api/v1/messages/task-2/reject');
        return messageActionResponse(
          messageJson(
            id: 'task-2',
            type: MessageType.tarefa,
            estado: MessageRecipientState.recusada,
          ),
        );
      }),
    );

    final updated = await rejectRepository.reject('task-2');
    expect(updated.estado, MessageRecipientState.recusada);
  });

  test('complete updates local cache', () async {
    await seedCachedMessage(
      db,
      id: 'task-3',
      type: MessageType.tarefa,
      estado: MessageRecipientState.aceita,
    );

    final completeRepository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        expect(request.url.path, '/api/v1/messages/task-3/complete');
        return messageActionResponse(
          messageJson(
            id: 'task-3',
            type: MessageType.tarefa,
            estado: MessageRecipientState.concluida,
          ),
        );
      }),
    );

    final updated = await completeRepository.complete('task-3');
    expect(updated.estado, MessageRecipientState.concluida);
  });
}
