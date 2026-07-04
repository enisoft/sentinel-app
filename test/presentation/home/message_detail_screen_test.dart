import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:sentinel_app/core/messages/message_recipient_state.dart';
import 'package:sentinel_app/core/messages/message_type.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/message_repository.dart';
import 'package:sentinel_app/presentation/home/message_detail_screen.dart';

import '../../support/message_test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('opening unread informe auto marks as read', (tester) async {
    await seedCachedMessage(
      db,
      id: 'informe-new',
      title: 'Aviso',
      body: 'Conteúdo do informe',
      estado: MessageRecipientState.enviada,
    );

    final repository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        expect(request.url.path, '/api/v1/messages/informe-new/read');
        return messageActionResponse(
          messageJson(
            id: 'informe-new',
            title: 'Aviso',
            body: 'Conteúdo do informe',
            estado: MessageRecipientState.lida,
            readAt: '2026-07-04T13:00:00Z',
          ),
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MessageDetailScreen(
          messageId: 'informe-new',
          messageRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('message_detail_screen')), findsOneWidget);
    expect(find.byKey(const Key('message_detail_status')), findsOneWidget);
    expect(find.text('Lida'), findsOneWidget);
    expect(find.text('Conteúdo do informe'), findsOneWidget);
    expect(find.byKey(const Key('message_accept_button')), findsNothing);
    expect((await repository.getById('informe-new'))!.estado,
        MessageRecipientState.lida);
  });

  testWidgets('tarefa lida shows accept and reject actions', (tester) async {
    await seedCachedMessage(
      db,
      id: 'task-open',
      title: 'Patrulha',
      body: 'Ir ao ponto X',
      type: MessageType.tarefa,
      estado: MessageRecipientState.lida,
    );

    final repository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        fail('read should not be called for already read task');
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MessageDetailScreen(
          messageId: 'task-open',
          messageRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('message_detail_tarefa_chip')), findsOneWidget);
    expect(find.byKey(const Key('message_accept_button')), findsOneWidget);
    expect(find.byKey(const Key('message_reject_button')), findsOneWidget);
    expect(find.byKey(const Key('message_complete_button')), findsNothing);
  });

  testWidgets('accept task updates detail to aceita with complete button',
      (tester) async {
    await seedCachedMessage(
      db,
      id: 'task-flow',
      title: 'Patrulha',
      body: 'Zona norte',
      type: MessageType.tarefa,
      estado: MessageRecipientState.lida,
    );

    final repository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        if (request.url.path.endsWith('/accept')) {
          return messageActionResponse(
            messageJson(
              id: 'task-flow',
              title: 'Patrulha',
              body: 'Zona norte',
              type: MessageType.tarefa,
              estado: MessageRecipientState.aceita,
            ),
          );
        }
        return messageActionResponse(messageJson(id: 'unused'));
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MessageDetailScreen(
          messageId: 'task-flow',
          messageRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('message_accept_button')));
    await tester.pumpAndSettle();

    expect(find.text('Aceita'), findsOneWidget);
    expect(find.byKey(const Key('message_complete_button')), findsOneWidget);
    expect(find.byKey(const Key('message_accept_button')), findsNothing);
    expect((await repository.getById('task-flow'))!.estado,
        MessageRecipientState.aceita);
  });

  testWidgets('complete task updates detail to concluida', (tester) async {
    await seedCachedMessage(
      db,
      id: 'task-done',
      title: 'Patrulha',
      type: MessageType.tarefa,
      estado: MessageRecipientState.aceita,
    );

    final repository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        expect(request.url.path, '/api/v1/messages/task-done/complete');
        return messageActionResponse(
          messageJson(
            id: 'task-done',
            type: MessageType.tarefa,
            estado: MessageRecipientState.concluida,
          ),
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MessageDetailScreen(
          messageId: 'task-done',
          messageRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('message_complete_button')));
    await tester.pumpAndSettle();

    expect(find.text('Concluída'), findsOneWidget);
    expect(find.byKey(const Key('message_complete_button')), findsNothing);
  });
}
