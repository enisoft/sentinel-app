import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/messages/message_recipient_state.dart';
import 'package:sentinel_app/core/messages/message_type.dart';
import 'package:sentinel_app/domain/models/inbox_message.dart';

void main() {
  group('InboxMessage.fromJson', () {
    test('parses full payload', () {
      final message = InboxMessage.fromJson({
        'id': 'msg-1',
        'author': 'Coordenador',
        'title': 'Aviso',
        'body': 'Corpo da mensagem',
        'type': MessageType.tarefa,
        'estado': MessageRecipientState.aceita,
        'created_at': '2026-07-04T12:00:00Z',
        'read_at': '2026-07-04T13:00:00Z',
        'acted_at': '2026-07-04T14:00:00Z',
      });

      expect(message.id, 'msg-1');
      expect(message.author, 'Coordenador');
      expect(message.title, 'Aviso');
      expect(message.body, 'Corpo da mensagem');
      expect(message.type, MessageType.tarefa);
      expect(message.estado, MessageRecipientState.aceita);
      expect(message.createdAt, DateTime.utc(2026, 7, 4, 12));
      expect(message.readAt, DateTime.utc(2026, 7, 4, 13));
      expect(message.actedAt, DateTime.utc(2026, 7, 4, 14));
      expect(message.isTarefa, isTrue);
      expect(message.isUnread, isFalse);
    });

    test('defaults missing optional fields', () {
      final message = InboxMessage.fromJson({
        'id': 'msg-min',
        'created_at': '2026-07-01T08:00:00Z',
      });

      expect(message.author, isEmpty);
      expect(message.title, isEmpty);
      expect(message.body, isEmpty);
      expect(message.type, MessageType.informe);
      expect(message.estado, MessageRecipientState.enviada);
      expect(message.readAt, isNull);
      expect(message.actedAt, isNull);
      expect(message.isUnread, isTrue);
      expect(message.displayTitle, 'Informe');
    });

    test('parses Portuguese API fields', () {
      final message = InboxMessage.fromJson({
        'id': 'rec-1',
        'message_id': 'msg-pt',
        'estado': 'enviada',
        'titulo': 'Aviso importante',
        'corpo': 'Texto do comando',
        'tipo': 'tarefa',
        'autor': 'Coordenação',
        'created_at': '2026-07-04T12:00:00Z',
      });

      expect(message.id, 'msg-pt');
      expect(message.title, 'Aviso importante');
      expect(message.body, 'Texto do comando');
      expect(message.type, MessageType.tarefa);
      expect(message.author, 'Coordenação');
      expect(message.displayTitle, 'Aviso importante');
    });

    test('parses nested message envelope from API', () {
      final message = InboxMessage.fromJson({
        'id': 'recipient-1',
        'estado': 'lida',
        'read_at': '2026-07-04T13:00:00Z',
        'message': {
          'id': 'msg-nested',
          'titulo': 'Informe zona sul',
          'corpo': 'Patrulha reforçada',
          'tipo': 'informe',
          'autor': {'nome': 'Maria Silva'},
          'created_at': '2026-07-04T10:00:00Z',
        },
      });

      expect(message.id, 'msg-nested');
      expect(message.title, 'Informe zona sul');
      expect(message.body, 'Patrulha reforçada');
      expect(message.estado, MessageRecipientState.lida);
      expect(message.author, 'Maria Silva');
      expect(message.type, MessageType.informe);
    });

    test('displayTitle falls back to first body line', () {
      final message = InboxMessage.fromJson({
        'id': 'msg-body',
        'corpo': 'Primeira linha\nSegunda linha',
        'tipo': 'informe',
        'created_at': '2026-07-04T12:00:00Z',
      });

      expect(message.displayTitle, 'Primeira linha');
    });

    test('copyWith overrides estado and timestamps', () {
      final original = InboxMessage(
        id: 'msg-1',
        author: 'A',
        title: 'T',
        body: 'B',
        type: MessageType.informe,
        estado: MessageRecipientState.enviada,
        createdAt: DateTime.utc(2026, 7, 4),
      );

      final updated = original.copyWith(
        estado: MessageRecipientState.lida,
        readAt: DateTime.utc(2026, 7, 4, 13),
      );

      expect(updated.estado, MessageRecipientState.lida);
      expect(updated.readAt, DateTime.utc(2026, 7, 4, 13));
      expect(updated.title, 'T');
    });
  });
}
