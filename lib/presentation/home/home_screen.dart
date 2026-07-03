import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../../data/services/occurrence_sync_foreground_runner.dart';
import '../../data/services/occurrence_sync_coordinator.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../capture/capture_home_screen.dart';
import 'occurrences_tab.dart';
import 'tasks_tab.dart';

/// Home com abas Ocorrências / Tasks e FAB de captura (ENI-57).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.authGateway,
    this.syncCoordinator,
    this.syncForegroundRunner,
    this.catalogSyncWarning,
    this.onRetryCatalogSync,
  });

  final AuthGateway? authGateway;
  final OccurrenceSyncCoordinator? syncCoordinator;
  final OccurrenceSyncForegroundRunner? syncForegroundRunner;
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

  @override
  void initState() {
    super.initState();
    _auth = widget.authGateway ?? getIt<AuthGateway>();
    _syncCoordinator =
        widget.syncCoordinator ?? getIt<OccurrenceSyncCoordinator>();
  }

  Future<void> _onLogout() async {
    await _auth.signOut();
  }

  Future<void> _openCapture() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const CaptureHomeScreen(),
      ),
    );
    if (!mounted) return;
    setState(() => _occurrencesRefreshToken++);
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
              : (_tabIndex == 0 ? 'Ocorrências' : 'Tasks'),
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
                : const TasksTab(),
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
          return BottomNavigationBar(
            key: const Key('home_bottom_nav'),
            currentIndex: _tabIndex,
            onTap: (index) => setState(() => _tabIndex = index),
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
              const BottomNavigationBarItem(
                key: Key('tasks_tab'),
                icon: Icon(Icons.task_alt),
                label: 'Tasks',
              ),
            ],
          );
        },
      ),
    );
  }
}
