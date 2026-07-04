/// Tipo de mensagem enviada pelo comando (`messages.tipo`).
abstract final class MessageType {
  static const informe = 'informe';
  static const tarefa = 'tarefa';

  static String normalize(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value == tarefa) return tarefa;
    return informe;
  }

  static bool isTarefa(String type) => normalize(type) == tarefa;

  static String listLabel(String type) =>
      isTarefa(type) ? 'Tarefa' : 'Informe';
}
