/// Textos de pendências de sync na UI (ENI-101).
abstract final class SyncPendingMessages {
  static String ownPendingBadge(int count) => '$count pendente(s)';

  static String otherOperatorPending(int count) =>
      '$count captura(s) de outro operador neste aparelho — sincronizar';

  static String logoutDialogContent(int count) =>
      'Você tem $count captura(s) não sincronizada(s). Sincronizar antes de sair?';

  static const logoutDialogTitle = 'Pendências não sincronizadas';

  static const logoutSyncNow = 'Sincronizar agora';

  static const logoutSignOutAnyway = 'Sair mesmo assim';

  static const logoutCancel = 'Cancelar';
}
