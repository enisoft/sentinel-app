import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../../core/sync/sync_foreground_notification_text.dart';
import '../../core/sync/sync_pending_messages.dart';

/// Barra única de estado de sincronização (UX-Fable).
///
/// Substitui a pilha de badges/botão/progresso da aba Ocorrências por um só
/// container tonal que muda de cor conforme o estado dominante:
/// falha > sincronizando > pendente > tudo sincronizado.
///
/// Mantém os contratos de teste existentes:
/// - `pending_sync_badge` presente sse [ownPendingCount] > 0;
/// - `other_operator_pending_badge` presente sse [otherOperatorPendingCount] > 0;
/// - `sync_progress_indicator` / `sync_progress_label` durante envio;
/// - `sync_now_button` sempre presente como [FilledButton], desabilitado
///   quando não há pendências ou já há sync em curso.
class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({
    super.key,
    required this.syncState,
    required this.ownPendingCount,
    required this.otherOperatorPendingCount,
    required this.onSyncNow,
  });

  final OccurrenceSyncCoordinatorState syncState;
  final int ownPendingCount;
  final int otherOperatorPendingCount;
  final VoidCallback onSyncNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sync = theme.syncStatusColors;

    final progressLabel = syncState.syncProgressCurrent != null &&
            syncState.syncProgressTotal != null
        ? SyncForegroundNotificationText.syncingProgress(
            current: syncState.syncProgressCurrent!,
            total: syncState.syncProgressTotal!,
          )
        : null;
    final hasFailure =
        syncState.lastResult != null && !syncState.lastResult!.success;
    final isSyncing = syncState.isSyncInProgress;
    final hasPending = ownPendingCount > 0 || otherOperatorPendingCount > 0;

    // Estado dominante define a cor do container.
    final (Color fg, Color bg) = hasFailure
        ? (sync.failed, sync.failedContainer)
        : isSyncing
            ? (sync.syncing, sync.syncingContainer)
            : hasPending
                ? (sync.pending, sync.pendingContainer)
                : (sync.synced, sync.syncedContainer);

    final statusText = TextStyle(
      color: fg,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSyncing && progressLabel != null)
                      Row(
                        children: [
                          SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              key: const Key('sync_progress_indicator'),
                              strokeWidth: 2,
                              color: fg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              progressLabel,
                              key: const Key('sync_progress_label'),
                              style: statusText,
                            ),
                          ),
                        ],
                      )
                    else if (ownPendingCount > 0)
                      Row(
                        key: const Key('pending_sync_badge'),
                        children: [
                          Icon(Icons.schedule, size: 14, color: fg),
                          const SizedBox(width: 6),
                          Text(
                            SyncPendingMessages.ownPendingBadge(
                              ownPendingCount,
                            ),
                            style: statusText.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    else if (!hasFailure)
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: fg),
                          const SizedBox(width: 6),
                          Text('Tudo sincronizado', style: statusText),
                        ],
                      ),
                    if (hasFailure)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          syncState.lastResult!.errorMessage ??
                              'Falha na sincronização',
                          style: statusText,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                key: const Key('sync_now_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed:
                    isSyncing || syncState.pendingCount == 0 ? null : onSyncNow,
                child: Text(
                  isSyncing
                      ? 'Sincronizando...'
                      : hasFailure
                          ? 'Tentar de novo'
                          : 'Sincronizar agora',
                ),
              ),
            ],
          ),
          if (otherOperatorPendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                key: const Key('other_operator_pending_badge'),
                children: [
                  Icon(Icons.people_outline, size: 14, color: fg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      SyncPendingMessages.otherOperatorPending(
                        otherOperatorPendingCount,
                      ),
                      style: statusText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
