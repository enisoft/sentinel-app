import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../../data/repositories/message_repository.dart';
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
    this.catalogSyncWarning,
    this.onRetryCatalogSync,
  });

  final AuthGateway? authGateway;
  final OccurrenceSyncCoordinator? syncCoordinator;
  final OccurrenceSyncForegroundRunner? syncForegroundRunner;
  final MessageRepository? messageRepository;
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

  @override
  void initState() {
    super.initState();
    _auth = widget.authGateway ?? getIt<AuthGateway>();
    _syncCoordinator =
        widget.syncCoordinator ?? getIt<OccurrenceSyncCoordinator>();
    _messageRepository =
        widget.messageRepository ?? getIt<MessageRepository>();
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
    await _auth.signOut();
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
    return Scaffold(
      key: const Key('home_screen'),
      appBar: AppBar(
        backgroundColor: widget.catalogSyncWarning != null
            ? Colors.orange.shade900
            : null,
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
              icon: const Icon(Icons.refresh),
              onPressed: widget.onRetryCatalogSync,
            ),
          IconButton(
            key: const Key('settings_button'),
            icon: const Icon(Icons.settings),
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
            MaterialBanner(
              content: Text(widget.catalogSyncWarning!),
              actions: [
                if (widget.onRetryCatalogSync != null)
                  TextButton(
                    onPressed: widget.onRetryCatalogSync,
                    child: const Text('Tentar novamente'),
                  ),
              ],
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
              return BottomNavigationBar(
                key: const Key('home_bottom_nav'),
                currentIndex: _tabIndex,
                onTap: (index) {
                  setState(() => _tabIndex = index);
                  if (index == 1) {
                    _refreshMessagesSilently();
                  }
                },
                items: [
                  BottomNavigationBarItem(
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
                  BottomNavigationBarItem(
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
