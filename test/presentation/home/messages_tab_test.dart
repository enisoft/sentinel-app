import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:sentinel_app/core/messages/message_recipient_state.dart';
import 'package:sentinel_app/core/messages/message_type.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/message_repository.dart';
import 'package:sentinel_app/presentation/home/message_detail_screen.dart';
import 'package:sentinel_app/presentation/home/messages_tab.dart';

import '../../support/message_test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<MessageRepository> buildRepository() async {
    final repository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        return messageListResponse([
          messageJson(
            id: 'msg-new',
            author: 'Coord',
            title: 'Aviso geral',
            body: 'Corpo',
            estado: MessageRecipientState.enviada,
          ),
          messageJson(
            id: 'msg-task',
            author: 'Coord',
            title: 'Patrulhar',
            body: 'Zona norte',
            type: MessageType.tarefa,
            estado: MessageRecipientState.lida,
            createdAt: '2026-07-03T10:00:00Z',
          ),
        ]);
      }),
    );
    await repository.refresh();
    return repository;
  }

  Future<void> pumpMessagesTab(
    WidgetTester tester,
    MessageRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessagesTab(
            messageRepository: repository,
            pollingEnabled: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when inbox has no messages', (tester) async {
    final repository = messageRepositoryWithClient(
      db,
      MockClient((request) async => messageListResponse([])),
    );
    await repository.refresh();

    await pumpMessagesTab(tester, repository);

    expect(find.byKey(const Key('messages_empty')), findsOneWidget);
    expect(find.text('Nenhuma mensagem'), findsOneWidget);
    expect(find.byKey(const Key('messages_list')), findsNothing);
  });

  testWidgets('shows list with tarefa highlighted and status labels',
      (tester) async {
    final repository = await buildRepository();
    await pumpMessagesTab(tester, repository);

    expect(find.byKey(const Key('messages_list')), findsOneWidget);
    expect(find.byKey(const Key('message_item_msg-new')), findsOneWidget);
    expect(find.byKey(const Key('message_item_msg-task')), findsOneWidget);
    expect(find.byKey(const Key('message_type_badge_msg-task')), findsOneWidget);
    expect(find.byKey(const Key('message_type_badge_msg-new')), findsOneWidget);
    expect(find.text('Tarefa'), findsOneWidget);
    expect(find.text('Informe'), findsOneWidget);

    expect(
      tester.widget<Text>(find.byKey(const Key('message_status_msg-new'))).data,
      'Nova',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('message_status_msg-task'))).data,
      'Lida',
    );
  });

  testWidgets('tap message opens detail screen', (tester) async {
    final repository = messageRepositoryWithClient(
      db,
      MockClient((request) async {
        return messageListResponse([
          messageJson(
            id: 'msg-open',
            title: 'Detalhe',
            body: 'Texto completo',
            estado: MessageRecipientState.lida,
          ),
        ]);
      }),
    );
    await repository.refresh();

    await pumpMessagesTab(tester, repository);

    await tester.tap(find.byKey(const Key('message_item_msg-open')));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailScreen), findsOneWidget);
    expect(find.text('Texto completo'), findsOneWidget);
    expect(find.text('Lida'), findsOneWidget);
  });
}
