import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/capture/occurrence_lifecycle_status.dart';
import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../../core/sync/sync_foreground_notification_text.dart';
import '../../core/sync/sync_state.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/occurrence_repository.dart';
import '../../data/services/occurrence_sync_coordinator.dart';
import '../../data/services/occurrence_sync_foreground_runner.dart';
import '../capture/occurrence_draft_form_screen.dart';
import 'occurrence_detail_screen.dart';

/// Lista local de ocorrências + badge/botão de sync (ENI-49 / ENI-57).
class OccurrencesTab extends StatefulWidget {
  const OccurrencesTab({
    super.key,
    this.refreshToken = 0,
    this.occurrenceRepository,
    this.syncCoordinator,
    this.syncForegroundRunner,
  });

  /// Incrementado pela home ao voltar da captura para recarregar a lista.
  final int refreshToken;

  final OccurrenceRepository? occurrenceRepository;
  final OccurrenceSyncCoordinator? syncCoordinator;
  final OccurrenceSyncForegroundRunner? syncForegroundRunner;

  @override
  State<OccurrencesTab> createState() => _OccurrencesTabState();
}

class _OccurrencesTabState extends State<OccurrencesTab> {
  List<Occurrence> _items = const [];
  late final OccurrenceRepository _occurrenceRepository;
  late final OccurrenceSyncCoordinator _syncCoordinator;
  late final OccurrenceSyncForegroundRunner _syncForegroundRunner;

  @override
  void initState() {
    super.initState();
    _occurrenceRepository =
        widget.occurrenceRepository ?? getIt<OccurrenceRepository>();
    _syncCoordinator =
        widget.syncCoordinator ?? getIt<OccurrenceSyncCoordinator>();
    _syncForegroundRunner =
        widget.syncForegroundRunner ?? getIt<OccurrenceSyncForegroundRunner>();
    _syncCoordinator.state.addListener(_onSyncStateChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant OccurrencesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  @override
  void dispose() {
    _syncCoordinator.state.removeListener(_onSyncStateChanged);
    super.dispose();
  }

  void _onSyncStateChanged() {
    _load();
  }

  Future<void> _load() async {
    final items = await _occurrenceRepository.listAll();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _onSyncNow() async {
    await _syncForegroundRunner.runIfPending();
  }

  Future<void> _onOccurrenceTap(Occurrence occurrence) async {
    if (occurrence.status == OccurrenceLifecycleStatus.draft) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OccurrenceDraftFormScreen(
            occurrenceId: occurrence.id,
            occurrenceRepository: _occurrenceRepository,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OccurrenceDetailScreen(
            occurrenceId: occurrence.id,
            occurrenceRepository: _occurrenceRepository,
          ),
        ),
      );
    }
    if (!mounted) return;
    await _load();
  }

  bool _isDraft(Occurrence occurrence) =>
      occurrence.status == OccurrenceLifecycleStatus.draft;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ValueListenableBuilder<OccurrenceSyncCoordinatorState>(
            valueListenable: _syncCoordinator.state,
            builder: (context, syncState, _) {
              final progressLabel = syncState.syncProgressCurrent != null &&
                      syncState.syncProgressTotal != null
                  ? SyncForegroundNotificationText.syncingProgress(
                      current: syncState.syncProgressCurrent!,
                      total: syncState.syncProgressTotal!,
                    )
                  : null;

              return Column(
                children: [
                  if (syncState.pendingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        key: const Key('pending_sync_badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${syncState.pendingCount} pendente(s)',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                  if (progressLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              key: Key('sync_progress_indicator'),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            key: const Key('sync_progress_label'),
                            progressLabel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  if (syncState.lastResult != null &&
                      !syncState.lastResult!.success)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        syncState.lastResult!.errorMessage ??
                            'Falha na sincronização',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      key: const Key('sync_now_button'),
                      onPressed: syncState.isSyncInProgress ||
                              syncState.pendingCount == 0
                          ? null
                          : _onSyncNow,
                      child: Text(
                        syncState.isSyncInProgress
                            ? (progressLabel ?? 'Sincronizando...')
                            : 'Sincronizar agora',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          key: Key('occurrences_empty'),
          'Nenhuma ocorrência ainda',
        ),
      );
    }

    return ListView.separated(
      key: const Key('occurrences_list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final occurrence = _items[index];
        final shortId = occurrenceShortId(occurrence.id);
        final isDraft = _isDraft(occurrence);
        return ListTile(
          key: Key('occurrence_item_${occurrence.id}'),
          leading: CircleAvatar(
            key: Key('occurrence_leading_${occurrence.id}'),
            backgroundColor: isDraft
                ? Colors.grey.shade300
                : Colors.green.shade50,
            child: Icon(
              isDraft ? Icons.edit_note : Icons.check_circle_outline,
              color: isDraft
                  ? Colors.grey.shade700
                  : Colors.green.shade700,
              size: 22,
            ),
          ),
          title: Text(_occurrenceTitle(occurrence)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatOccurredAt(occurrence.occurredAt)),
              const SizedBox(height: 4),
              Container(
                key: Key('occurrence_id_badge_${occurrence.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDraft
                      ? Colors.amber.shade50
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                  border: isDraft
                      ? Border.all(color: Colors.amber.shade200)
                      : null,
                ),
                child: Text(
                  isDraft ? 'Rascunho · $shortId' : shortId,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: isDraft
                            ? Colors.amber.shade900
                            : Colors.grey.shade700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: Text(
            key: Key('occurrence_status_${occurrence.id}'),
            occurrenceListStatusLabel(occurrence),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _statusColor(occurrence),
                  fontWeight: FontWeight.w600,
                ),
          ),
          onTap: () => _onOccurrenceTap(occurrence),
        );
      },
    );
  }

  String _occurrenceTitle(Occurrence occurrence) {
    final title = occurrence.title.trim();
    if (title.isNotEmpty) return title;
    final description = occurrence.description.trim();
    if (description.isNotEmpty) return description;
    return 'Ocorrência';
  }

  String _formatOccurredAt(DateTime occurredAt) {
    final local = occurredAt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Color _statusColor(Occurrence occurrence) {
    if (occurrence.status == OccurrenceLifecycleStatus.draft) {
      return Colors.grey.shade700;
    }
    return switch (occurrence.syncState) {
      SyncState.synced => Colors.green.shade700,
      SyncState.failed => Colors.redAccent,
      SyncState.mediaUploading ||
      SyncState.mediaDone ||
      SyncState.jsonSyncing =>
        Colors.blueGrey,
      SyncState.localSaved => Colors.orange.shade800,
    };
  }
}

/// Prefixo curto do id (estilo hash do GitHub) para localização em testes.
String occurrenceShortId(String id) {
  if (id.length <= 6) return id;
  return id.substring(0, 6);
}

/// Rótulo de estado por item: rascunhos não contam como pendente de sync (ENI-44).
String occurrenceListStatusLabel(Occurrence occurrence) {
  if (occurrence.status == OccurrenceLifecycleStatus.draft) {
    return 'Não confirmada';
  }
  return switch (occurrence.syncState) {
    SyncState.synced => 'Sincronizada',
    SyncState.failed => 'Falha',
    SyncState.mediaUploading ||
    SyncState.mediaDone ||
    SyncState.jsonSyncing =>
      'Sincronizando',
    SyncState.localSaved => 'Pendente',
  };
}
