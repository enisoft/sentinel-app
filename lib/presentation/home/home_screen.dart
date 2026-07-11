import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../app/theme.dart';
import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../../core/sync/sync_pending_messages.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/sync_queue_repository.dart';
import '../../data/services/occurrence_sync_foreground_runner.dart';
import '../../data/services/occurrence_sync_coordinator.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../capture/capture_home_screen.dart';
import '../settings/settings_screen.dart';
import 'messages_tab.dart';
import 'occurrences_tab.dart';

/// Home com abas Ocorrências / Mensagens e FAB de captura (ENI-57).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.authGateway,
    this.syncCoordinator,
    this.syncForegroundRunner,
    this.messageRepository,
    this.syncQueueRepository,
    this.catalogSyncWarning,
    this.onRetryCatalogSync,
  });

  final AuthGateway? authGateway;
  final OccurrenceSyncCoordinator? syncCoordinator;
  final OccurrenceSyncForegroundRunner? syncForegroundRunner;
  final MessageRepository? messageRepository;
  final SyncQueueRepository? syncQueueRepository;
  final String? catalogSyncWarning;
  final VoidCallback? onRetryCatalogSync;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  int _occurrencesRefreshToken = 0;
  late final AuthGateway _auth;
  late final OccurrenceSyncCoordinator _syncCoordinator;
  late final MessageRepository _messageRepository;
  late final SyncQueueRepository _syncQueueRepository;
  late final OccurrenceSyncForegroundRunner _syncForegroundRunner;

  @override
  void initState() {
    super.initState();
    _auth = widget.authGateway ?? getIt<AuthGateway>();
    _syncCoordinator =
        widget.syncCoordinator ?? getIt<OccurrenceSyncCoordinator>();
    _messageRepository =
        widget.messageRepository ?? getIt<MessageRepository>();
    _syncQueueRepository =
        widget.syncQueueRepository ?? getIt<SyncQueueRepository>();
    _syncForegroundRunner =
        widget.syncForegroundRunner ?? getIt<OccurrenceSyncForegroundRunner>();
    _refreshMessagesSilently();
  }

  Future<void> _refreshMessagesSilently() async {
    try {
      await _messageRepository.refresh();
    } on Object {
      // Mantém cache local; badge/lista atualizam na próxima tentativa.
    }
  }

  Future<void> _onLogout() async {
    final operatorUid = _auth.currentUserId;
    if (operatorUid == null) {
      await _auth.signOut();
      return;
    }

    final ownPending =
        await _syncQueueRepository.countPendingOccurrencesForOperator(
      operatorUid,
    );
    if (ownPending == 0) {
      await _auth.signOut();
      return;
    }

    if (!mounted) return;
    final action = await showDialog<_LogoutPendingAction>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('logout_pending_dialog'),
        title: const Text(SyncPendingMessages.logoutDialogTitle),
        content: Text(SyncPendingMessages.logoutDialogContent(ownPending)),
        actions: [
          TextButton(
            key: const Key('logout_pending_cancel'),
            onPressed: () =>
                Navigator.of(context).pop(_LogoutPendingAction.cancel),
            child: const Text(SyncPendingMessages.logoutCancel),
          ),
          TextButton(
            key: const Key('logout_pending_sign_out'),
            onPressed: () =>
                Navigator.of(context).pop(_LogoutPendingAction.signOutAnyway),
            child: const Text(SyncPendingMessages.logoutSignOutAnyway),
          ),
          FilledButton(
            key: const Key('logout_pending_sync'),
            onPressed: () =>
                Navigator.of(context).pop(_LogoutPendingAction.syncNow),
            child: const Text(SyncPendingMessages.logoutSyncNow),
          ),
        ],
      ),
    );

    switch (action) {
      case _LogoutPendingAction.syncNow:
        await _syncForegroundRunner.runIfPending();
      case _LogoutPendingAction.signOutAnyway:
        await _auth.signOut();
      case _LogoutPendingAction.cancel:
      case null:
        break;
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  Future<void> _openCapture() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const CaptureHomeScreen(),
      ),
    );
    if (!mounted) return;
    setState(() => _occurrencesRefreshToken++);
    _refreshMessagesSilently();
  }

  @override
  Widget build(BuildContext context) {
    final sync = Theme.of(context).syncStatusColors;
    return Scaffold(
      key: const Key('home_screen'),
      appBar: AppBar(
        title: Text(
          widget.catalogSyncWarning != null
              ? 'Catálogo desatualizado'
              : (_tabIndex == 0 ? 'Ocorrências' : 'Mensagens'),
        ),
        actions: [
          if (widget.catalogSyncWarning != null &&
              widget.onRetryCatalogSync != null)
            IconButton(
              key: const Key('retry_catalog_sync'),
              icon: Icon(Icons.refresh, color: sync.pending),
              onPressed: widget.onRetryCatalogSync,
            ),
          IconButton(
            key: const Key('settings_button'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: _onLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.catalogSyncWarning != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: sync.pendingContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: sync.pending),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.catalogSyncWarning!,
                        style: TextStyle(
                          color: sync.pending,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.onRetryCatalogSync != null)
                      TextButton(
                        onPressed: widget.onRetryCatalogSync,
                        style: TextButton.styleFrom(
                          foregroundColor: sync.pending,
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _tabIndex == 0
                ? OccurrencesTab(
                    refreshToken: _occurrencesRefreshToken,
                    syncCoordinator: _syncCoordinator,
                    syncForegroundRunner: widget.syncForegroundRunner,
                  )
                : MessagesTab(messageRepository: _messageRepository),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_occurrence_fab'),
        onPressed: _openCapture,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Adicionar ocorrência'),
      ),
      bottomNavigationBar: ValueListenableBuilder<OccurrenceSyncCoordinatorState>(
        valueListenable: _syncCoordinator.state,
        builder: (context, syncState, _) {
          final pendingCount = syncState.pendingCount;
          return ValueListenableBuilder<int>(
            valueListenable: _messageRepository.unreadCount,
            builder: (context, unreadCount, _) {
              return NavigationBar(
                key: const Key('home_bottom_nav'),
                selectedIndex: _tabIndex,
                onDestinationSelected: (index) {
                  setState(() => _tabIndex = index);
                  if (index == 1) {
                    _refreshMessagesSilently();
                  }
                },
                destinations: [
                  NavigationDestination(
                    key: const Key('occurrences_tab'),
                    icon: Badge(
                      key: const Key('occurrences_tab_badge'),
                      isLabelVisible: pendingCount > 0,
                      label: Text(
                        key: const Key('occurrences_tab_badge_count'),
                        pendingCount > 99 ? '99+' : '$pendingCount',
                      ),
                      child: const Icon(Icons.list_alt),
                    ),
                    label: 'Ocorrências',
                  ),
                  NavigationDestination(
                    key: const Key('messages_tab'),
                    icon: Badge(
                      key: const Key('messages_tab_badge'),
                      isLabelVisible: unreadCount > 0,
                      label: Text(
                        key: const Key('messages_tab_badge_count'),
                        unreadCount > 99 ? '99+' : '$unreadCount',
                      ),
                      child: const Icon(Icons.mail_outline),
                    ),
                    label: 'Mensagens',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

enum _LogoutPendingAction { syncNow, signOutAnyway, cancel }
