/// Estado do destinatário (`message_recipients.estado`).
abstract final class MessageRecipientState {
  static const enviada = 'enviada';
  static const lida = 'lida';
  static const aceita = 'aceita';
  static const concluida = 'concluida';
  static const recusada = 'recusada';

  static bool isUnread(String estado) => estado == enviada;

  static String normalize(String? raw) {
    final value = raw?.trim().toLowerCase() ?? enviada;
    return switch (value) {
      enviada => enviada,
      lida => lida,
      aceita => aceita,
      concluida => concluida,
      recusada => recusada,
      _ => value.isEmpty ? enviada : value,
    };
  }

  static String listLabel(String estado) => switch (normalize(estado)) {
        enviada => 'Nova',
        lida => 'Lida',
        aceita => 'Aceita',
        concluida => 'Concluída',
        recusada => 'Recusada',
        _ => estado,
      };
}
