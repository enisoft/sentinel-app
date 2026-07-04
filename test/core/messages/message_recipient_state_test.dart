import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/messages/message_recipient_state.dart';

void main() {
  group('MessageRecipientState', () {
    test('isUnread is true only for enviada', () {
      expect(MessageRecipientState.isUnread(MessageRecipientState.enviada), isTrue);
      expect(MessageRecipientState.isUnread(MessageRecipientState.lida), isFalse);
      expect(MessageRecipientState.isUnread(MessageRecipientState.aceita), isFalse);
      expect(MessageRecipientState.isUnread(MessageRecipientState.concluida), isFalse);
      expect(MessageRecipientState.isUnread(MessageRecipientState.recusada), isFalse);
    });

    test('listLabel maps known estados', () {
      expect(MessageRecipientState.listLabel(MessageRecipientState.enviada), 'Nova');
      expect(MessageRecipientState.listLabel(MessageRecipientState.lida), 'Lida');
      expect(MessageRecipientState.listLabel(MessageRecipientState.aceita), 'Aceita');
      expect(MessageRecipientState.listLabel(MessageRecipientState.concluida), 'Concluída');
      expect(MessageRecipientState.listLabel(MessageRecipientState.recusada), 'Recusada');
    });

    test('listLabel falls back to raw estado', () {
      expect(MessageRecipientState.listLabel('desconhecido'), 'desconhecido');
    });
  });
}
