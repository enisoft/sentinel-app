import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/capture/video_recording_policy.dart';
import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../../core/sync/sync_foreground_notification_text.dart';
import '../../data/device/camera_permission_denied_exception.dart';
import '../../data/device/device_camera_source.dart';
import '../../data/local/app_database.dart';
import '../../data/services/capture_occurrence_service.dart';
import '../../data/services/occurrence_sync_foreground_runner.dart';
import '../../data/services/occurrence_sync_coordinator.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';
import 'in_app_camera_preview.dart';
import 'in_app_capture_controls.dart';
import 'occurrence_draft_form_screen.dart';

/// Home capture-first: câmera in-app (device) ou placeholder (testes/fake).
///
/// ENI-60 — captura em sequência sem sair do preview; form só em "Concluir".
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
  bool _cameraPermissionDenied = false;
  bool _cameraReady = false;
  String? _activeDraftId;
  List<OccurrenceMediaData> _draftMedia = [];

  CaptureOccurrenceService get _captureService =>
      widget.captureService ?? getIt<CaptureOccurrenceService>();

  CameraSource? get _cameraSource {
    try {
      return getIt<CameraSource>();
    } catch (_) {
      return null;
    }
  }

  DeviceCameraSource? get _deviceCameraSource {
    final source = _cameraSource;
    return source is DeviceCameraSource ? source : null;
  }

  bool get _canInteract {
    if (_deviceCameraSource != null) {
      return _cameraReady && !_cameraPermissionDenied;
    }
    return true;
  }

  bool get _hasDraftMedia => _draftMedia.isNotEmpty;

  AuthGateway get _auth => widget.authGateway ?? getIt<AuthGateway>();

  OccurrenceSyncCoordinator get _syncCoordinator =>
      widget.syncCoordinator ?? getIt<OccurrenceSyncCoordinator>();

  OccurrenceSyncForegroundRunner get _syncForegroundRunner =>
      widget.syncForegroundRunner ?? getIt<OccurrenceSyncForegroundRunner>();

  Future<void> _onSyncNow() async {
    await _syncForegroundRunner.runIfPending();
  }

  Future<void> _reloadDraftMedia() async {
    final draftId = _activeDraftId;
    if (draftId == null) {
      if (mounted) setState(() => _draftMedia = []);
      return;
    }
    final media = await _captureService.listDraftMedia(draftId);
    if (!mounted) return;
    setState(() => _draftMedia = media);
  }

  void _clearActiveDraft() {
    setState(() {
      _activeDraftId = null;
      _draftMedia = [];
    });
  }

  Future<void> _onCaptureComplete(CaptureResult capture) async {
    try {
      final draftId = _activeDraftId;
      if (draftId == null) {
        final draft = await _captureService.createDraftFromCapture(capture);
        if (!mounted) return;
        setState(() => _activeDraftId = draft.occurrence.id);
      } else {
        await _captureService.attachCaptureToDraft(
          occurrenceId: draftId,
          capture: capture,
        );
      }
      await _reloadDraftMedia();
    } on CameraPermissionDeniedException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na captura: $error')),
      );
    }
  }

  void _onCaptureError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onLegacyCapture() async {
    try {
      final draftId = _activeDraftId;
      if (draftId == null) {
        final draft = await _captureService.captureDraft();
        if (!mounted) return;
        setState(() => _activeDraftId = draft.occurrence.id);
      } else {
        await _captureService.addMediaToDraft(draftId);
      }
      await _reloadDraftMedia();
    } on CameraPermissionDeniedException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na captura: $error')),
      );
    }
  }

  Future<void> _onFinishDraft() async {
    final draftId = _activeDraftId;
    if (draftId == null || _draftMedia.isEmpty) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OccurrenceDraftFormScreen(
          occurrenceId: draftId,
          captureService: _captureService,
        ),
      ),
    );
    if (!mounted) return;

    final stillDraft = await _captureService.isDraft(draftId);
    if (!mounted) return;
    if (!stillDraft) {
      _clearActiveDraft();
    } else {
      await _reloadDraftMedia();
    }
  }

  Future<void> _onRemoveMedia(String mediaId) async {
    final draftId = _activeDraftId;
    if (draftId == null) return;
    try {
      await _captureService.removeMediaFromDraft(
        occurrenceId: draftId,
        mediaId: mediaId,
      );
      await _reloadDraftMedia();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao remover mídia: $error')),
      );
    }
  }

  Future<void> _openMediaCart() async {
    if (!_hasDraftMedia) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _DraftMediaCartSheet(
              media: _draftMedia,
              onRemoveMedia: (mediaId) async {
                await _onRemoveMedia(mediaId);
                if (!sheetContext.mounted) return;
                if (_draftMedia.isEmpty) {
                  Navigator.of(sheetContext).pop();
                } else {
                  setSheetState(() {});
                }
              },
            );
          },
        );
      },
    );
    await _reloadDraftMedia();
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
            _buildCameraLayer(),
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
                      final progressLabel =
                          syncState.syncProgressCurrent != null &&
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
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
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    key: const Key('sync_progress_label'),
                                    progressLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white70),
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
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
                  if (_cameraSource != null)
                    InAppCaptureControls(
                      cameraSource: _cameraSource!,
                      canInteract: _canInteract,
                      onCaptureComplete: _onCaptureComplete,
                      onError: _onCaptureError,
                    )
                  else
                    Semantics(
                      label: 'Capturar ocorrência',
                      button: true,
                      child: GestureDetector(
                        key: const Key('capture_button'),
                        onTap: _canInteract ? _onLegacyCapture : null,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color:
                                _canInteract ? Colors.white : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_hasDraftMedia) ...[
              Positioned(
                left: 24,
                bottom: 48,
                child: _DraftMediaCartButton(
                  mediaCount: _draftMedia.length,
                  lastMedia: _draftMedia.last,
                  onTap: _openMediaCart,
                ),
              ),
              Positioned(
                right: 24,
                bottom: 56,
                child: FilledButton(
                  key: const Key('finish_draft_button'),
                  onPressed: _onFinishDraft,
                  child: const Text('Concluir'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    final deviceSource = _deviceCameraSource;
    if (deviceSource != null) {
      return InAppCameraPreview(
        cameraSource: deviceSource,
        onPermissionDenied: (denied) {
          if (mounted) setState(() => _cameraPermissionDenied = denied);
        },
        onReadyChanged: (ready) {
          if (mounted) setState(() => _cameraReady = ready);
        },
      );
    }

    return const Center(
      child: Icon(Icons.photo_camera_outlined, size: 96, color: Colors.white24),
    );
  }
}

class _DraftMediaCartButton extends StatelessWidget {
  const _DraftMediaCartButton({
    required this.mediaCount,
    required this.lastMedia,
    required this.onTap,
  });

  final int mediaCount;
  final OccurrenceMediaData lastMedia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('draft_media_cart'),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _MediaThumbnail(media: lastMedia),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              key: const Key('draft_media_count'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$mediaCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftMediaCartSheet extends StatelessWidget {
  const _DraftMediaCartSheet({
    required this.media,
    required this.onRemoveMedia,
  });

  final List<OccurrenceMediaData> media;
  final Future<void> Function(String mediaId) onRemoveMedia;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              key: const Key('draft_media_cart_sheet'),
              'Mídias capturadas (${media.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                key: const Key('draft_media_cart_list'),
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = media[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: _MediaThumbnail(media: item),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: IconButton(
                            key: Key('remove_media_${item.id}'),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => onRemoveMedia(item.id),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.media});

  final OccurrenceMediaData media;

  @override
  Widget build(BuildContext context) {
    if (media.mediaType == 'image') {
      final file = File(media.localPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
      return _placeholder();
    }
    if (media.mediaType == 'video') {
      return _videoPlaceholder();
    }
    return _placeholder();
  }

  Widget _videoPlaceholder() {
    final duration = media.durationSeconds;
    return ColoredBox(
      color: Colors.grey.shade800,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Center(
            child: Icon(Icons.videocam, color: Colors.white70, size: 28),
          ),
          if (duration != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  formatRecordingElapsed(duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.grey.shade700,
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white54),
      ),
    );
  }
}
