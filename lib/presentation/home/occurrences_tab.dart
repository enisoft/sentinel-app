import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../app/theme.dart';
import '../../core/capture/occurrence_lifecycle_status.dart';
import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../../core/sync/sync_state.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/occurrence_repository.dart';
import '../../data/repositories/sync_queue_repository.dart';
import '../../data/services/occurrence_sync_coordinator.dart';
import '../../data/services/occurrence_sync_foreground_runner.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../capture/occurrence_draft_form_screen.dart';
import '../shared/status_chip.dart';
import '../shared/sync_status_bar.dart';
import 'occurrence_detail_screen.dart';

/// Lista local de ocorrências + badge/botão de sync (ENI-49 / ENI-57).
class OccurrencesTab extends StatefulWidget {
  const OccurrencesTab({
    super.key,
    this.refreshToken = 0,
    this.occurrenceRepository,
    this.syncCoordinator,
    this.syncForegroundRunner,
    this.authGateway,
    this.syncQueueRepository,
  });

  /// Incrementado pela home ao voltar da captura para recarregar a lista.
  final int refreshToken;

  final OccurrenceRepository? occurrenceRepository;
  final OccurrenceSyncCoordinator? syncCoordinator;
  final OccurrenceSyncForegroundRunner? syncForegroundRunner;
  final AuthGateway? authGateway;
  final SyncQueueRepository? syncQueueRepository;

  @override
  State<OccurrencesTab> createState() => _OccurrencesTabState();
}

class _OccurrencesTabState extends State<OccurrencesTab> {
  List<Occurrence> _items = const [];
  int _ownPendingCount = 0;
  int _otherOperatorPendingCount = 0;
  late final OccurrenceRepository _occurrenceRepository;
  late final OccurrenceSyncCoordinator _syncCoordinator;
  late final OccurrenceSyncForegroundRunner _syncForegroundRunner;
  late final AuthGateway _authGateway;
  late final SyncQueueRepository _syncQueueRepository;

  @override
  void initState() {
    super.initState();
    _occurrenceRepository =
        widget.occurrenceRepository ?? getIt<OccurrenceRepository>();
    _syncCoordinator =
        widget.syncCoordinator ?? getIt<OccurrenceSyncCoordinator>();
    _syncForegroundRunner =
        widget.syncForegroundRunner ?? getIt<OccurrenceSyncForegroundRunner>();
    _authGateway = widget.authGateway ?? getIt<AuthGateway>();
    _syncQueueRepository =
        widget.syncQueueRepository ?? getIt<SyncQueueRepository>();
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
    final operatorUid = _authGateway.currentUserId;
    final items = operatorUid == null
        ? const <Occurrence>[]
        : await _occurrenceRepository.listForOperator(operatorUid);
    final ownPending = operatorUid == null
        ? 0
        : await _syncQueueRepository.countOwnPendingForOperator(operatorUid);
    final otherPending = operatorUid == null
        ? 0
        : await _syncQueueRepository
            .countPendingOccurrencesForOtherOperators(operatorUid);
    if (!mounted) return;
    setState(() {
      _items = items;
      _ownPendingCount = ownPending;
      _otherOperatorPendingCount = otherPending;
    });
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: ValueListenableBuilder<OccurrenceSyncCoordinatorState>(
            valueListenable: _syncCoordinator.state,
            builder: (context, syncState, _) {
              return SyncStatusBar(
                syncState: syncState,
                ownPendingCount: _ownPendingCount,
                otherOperatorPendingCount: _otherOperatorPendingCount,
                onSyncNow: _onSyncNow,
              );
            },
          ),
        ),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            const Text(
              key: Key('occurrences_empty'),
              'Nenhuma ocorrência ainda',
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      key: const Key('occurrences_list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _buildCard(context, _items[index]),
    );
  }

  Widget _buildCard(BuildContext context, Occurrence occurrence) {
    final theme = Theme.of(context);
    final sync = theme.syncStatusColors;
    final shortId = occurrenceShortId(occurrence.id);
    final isDraft = _isDraft(occurrence);
    final (chipFg, chipBg) = _statusChipColors(occurrence, sync);

    return Material(
      key: Key('occurrence_item_${occurrence.id}'),
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _onOccurrenceTap(occurrence),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _occurrenceTitle(occurrence),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    label: occurrenceListStatusLabel(occurrence),
                    textKey: Key('occurrence_status_${occurrence.id}'),
                    foreground: chipFg,
                    background: chipBg,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatOccurredAt(occurrence.occurredAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    key: Key('occurrence_id_badge_${occurrence.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDraft
                          ? sync.pendingContainer
                          : theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isDraft ? 'Rascunho · $shortId' : shortId,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: isDraft
                            ? sync.pending
                            : theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  /// Par (texto, fundo) do chip de estado, a partir dos tokens semânticos.
  (Color, Color) _statusChipColors(
    Occurrence occurrence,
    SyncStatusColors sync,
  ) {
    if (occurrence.status == OccurrenceLifecycleStatus.draft) {
      return (sync.draft, sync.draftContainer);
    }
    return switch (occurrence.syncState) {
      SyncState.synced => (sync.synced, sync.syncedContainer),
      SyncState.failed => (sync.failed, sync.failedContainer),
      SyncState.mediaUploading ||
      SyncState.mediaDone ||
      SyncState.jsonSyncing =>
        (sync.syncing, sync.syncingContainer),
      SyncState.localSaved => (sync.pending, sync.pendingContainer),
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
