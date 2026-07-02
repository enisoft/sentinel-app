/// Textos da notificação do Foreground Service de sync (ENI-42).
class SyncForegroundNotificationText {
  const SyncForegroundNotificationText._();

  static const titleSending = 'Sincronizando ocorrências…';
  static const titleWaiting = 'Ocorrências pendentes';

  static String sendingProgress({required int current, required int total}) =>
      'Enviando $current de $total';

  static String syncingProgress({required int current, required int total}) =>
      'Sincronizando $current de $total';

  static String waitingForConnection(int pendingCount) =>
      '$pendingCount pendente(s), aguardando conexão';
}
