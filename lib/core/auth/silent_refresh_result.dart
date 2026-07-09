/// Resultado de [AuthGateway.tryRefreshSessionSilently] (ENI-105).
class SilentRefreshResult {
  const SilentRefreshResult({
    required this.refreshed,
    this.serverUnreachable = false,
  });

  final bool refreshed;

  /// Refresh falhou por rede/timeout — sessão persistida intacta (ENI-84).
  final bool serverUnreachable;
}
