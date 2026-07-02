import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/sync/sync_foreground_notification_text.dart';

void main() {
  test('waitingForConnection formats pending count', () {
    expect(
      SyncForegroundNotificationText.waitingForConnection(3),
      '3 pendente(s), aguardando conexão',
    );
  });

  test('syncingProgress formats current and total', () {
    expect(
      SyncForegroundNotificationText.syncingProgress(current: 2, total: 4),
      'Sincronizando 2 de 4',
    );
  });

  test('sendingProgress formats current and total', () {
    expect(
      SyncForegroundNotificationText.sendingProgress(current: 2, total: 4),
      'Enviando 2 de 4',
    );
  });
}
