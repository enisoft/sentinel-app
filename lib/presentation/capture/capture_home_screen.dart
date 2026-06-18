import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../../data/services/capture_occurrence_service.dart';
import '../../data/services/occurrence_sync_foreground_runner.dart';
import '../../data/services/occurrence_sync_coordinator.dart';
import '../../domain/gateways/auth_gateway.dart';
import 'occurrence_draft_form_screen.dart';

/// Home capture-first: placeholder de câmera que dispara captura via fake/device.
class CaptureHomeScreen extends StatefulWidget {
  const CaptureHomeScreen({
    super.key,
    this.captureService,
    this.authGateway,
    this.syncCoordinator,
    this.syncForegroundRunner,
    this.catalogSyncWarning,
    this.onRetryCatalogSync,
  });

  final CaptureOccurrenceService? captureService;
  final AuthGateway? authGateway;
  final OccurrenceSyncCoordinator? syncCoordinator;
  final OccurrenceSyncForegroundRunner? syncForegroundRunner;
  final String? catalogSyncWarning;
  final VoidCallback? onRetryCatalogSync;

  @override
  State<CaptureHomeScreen> createState() => _CaptureHomeScreenState();
}

class _CaptureHomeScreenState extends State<CaptureHomeScreen> {
  bool _capturing = false;

  CaptureOccurrenceService get _captureService =>
      widget.captureService ?? getIt<CaptureOccurrenceService>();

  AuthGateway get _auth => widget.authGateway ?? getIt<AuthGateway>();

  OccurrenceSyncCoordinator get _syncCoordinator =>
      widget.syncCoordinator ?? getIt<OccurrenceSyncCoordinator>();

  OccurrenceSyncForegroundRunner get _syncForegroundRunner =>
      widget.syncForegroundRunner ?? getIt<OccurrenceSyncForegroundRunner>();

  Future<void> _onSyncNow() async {
    await _syncForegroundRunner.runIfPending();
  }

  Future<void> _onCapturePressed() async {
    if (_capturing) return;
    setState(() => _capturing = true);

    try {
      final draft = await _captureService.captureDraft();
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OccurrenceDraftFormScreen(
            occurrenceId: draft.occurrence.id,
            captureService: _captureService,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na captura: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _onLogout() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.catalogSyncWarning != null
          ? AppBar(
              backgroundColor: Colors.orange.shade900,
              title: const Text('Catálogo desatualizado'),
              actions: [
                if (widget.onRetryCatalogSync != null)
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
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  key: const Key('logout_button'),
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  onPressed: _onLogout,
                ),
              ],
            ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: Icon(Icons.photo_camera_outlined, size: 96, color: Colors.white24),
            ),
            if (widget.catalogSyncWarning != null)
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                child: MaterialBanner(
                  content: Text(widget.catalogSyncWarning!),
                  actions: [
                    if (widget.onRetryCatalogSync != null)
                      TextButton(
                        onPressed: widget.onRetryCatalogSync,
                        child: const Text('Tentar novamente'),
                      ),
                  ],
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Column(
                children: [
                  ValueListenableBuilder<OccurrenceSyncCoordinatorState>(
                    valueListenable: _syncCoordinator.state,
                    builder: (context, syncState, _) {
                      return Column(
                        children: [
                          if (syncState.pendingCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${syncState.pendingCount} pendente(s)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white70),
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: FilledButton.tonal(
                              key: const Key('sync_now_button'),
                              onPressed: syncState.isSyncing ? null : _onSyncNow,
                              child: Text(
                                syncState.isSyncing
                                    ? 'Sincronizando...'
                                    : 'Sincronizar agora',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Text(
                    'Toque para capturar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Capturar ocorrência',
                    button: true,
                    child: GestureDetector(
                      key: const Key('capture_button'),
                      onTap: _capturing ? null : _onCapturePressed,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _capturing ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
