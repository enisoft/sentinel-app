import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../domain/models/capture_result.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/services/capture_occurrence_service.dart';
import 'in_app_capture_screen.dart';

/// Form mínimo pós-captura — nunca bloqueia o disparo anterior.
class OccurrenceDraftFormScreen extends StatefulWidget {
  const OccurrenceDraftFormScreen({
    super.key,
    required this.occurrenceId,
    this.captureService,
    this.catalogRepository,
  });

  final String occurrenceId;
  final CaptureOccurrenceService? captureService;
  final CatalogRepository? catalogRepository;

  @override
  State<OccurrenceDraftFormScreen> createState() =>
      _OccurrenceDraftFormScreenState();
}

class _OccurrenceDraftFormScreenState extends State<OccurrenceDraftFormScreen> {
  final _noteController = TextEditingController();
  bool _confirming = false;
  bool _addingMedia = false;
  String? _categoryId;
  String? _observableId;
  List<OccurrenceMediaData> _media = [];
  late final Future<List<CatalogItem>> _categoriesFuture;
  late final Future<List<CatalogItem>> _observablesFuture;

  CaptureOccurrenceService get _captureService =>
      widget.captureService ?? getIt<CaptureOccurrenceService>();

  CatalogRepository get _catalog =>
      widget.catalogRepository ?? getIt<CatalogRepository>();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _catalog.getCategories();
    _observablesFuture = _catalog.getObservables();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final media = await _captureService.listDraftMedia(widget.occurrenceId);
    if (mounted) setState(() => _media = media);
  }

  Future<void> _onAddMedia() async {
    if (_addingMedia) return;
    setState(() => _addingMedia = true);

    try {
      final capture = await Navigator.of(context).push<CaptureResult>(
        MaterialPageRoute(
          builder: (_) => const InAppCaptureScreen(),
        ),
      );
      if (capture == null || !mounted) return;

      await _captureService.attachCaptureToDraft(
        occurrenceId: widget.occurrenceId,
        capture: capture,
      );
      await _loadMedia();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao adicionar mídia: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _addingMedia = false);
    }
  }

  Future<void> _onRemoveMedia(String mediaId) async {
    try {
      await _captureService.removeMediaFromDraft(
        occurrenceId: widget.occurrenceId,
        mediaId: mediaId,
      );
      await _loadMedia();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao remover mídia: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _syncDraft() {
    _captureService.updateDraftForm(
      occurrenceId: widget.occurrenceId,
      categoryId: _categoryId,
      observableId: _observableId,
      note: _emptyToNull(_noteController.text),
    );
  }

  Future<void> _onConfirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);

    try {
      await _captureService.confirmDraft(
        occurrenceId: widget.occurrenceId,
        categoryId: _categoryId,
        observableId: _observableId,
        note: _emptyToNull(_noteController.text),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorrência na fila de sync')),
      );
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da ocorrência')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            _DraftMediaSection(
              media: _media,
              addingMedia: _addingMedia,
              onAddMedia: _onAddMedia,
              onRemoveMedia: _onRemoveMedia,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<CatalogItem>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Text(
                    key: Key('catalog_empty_warning'),
                    'Catálogo vazio — selecione após sincronizar ou confirme sem categoria.',
                  );
                }
                return DropdownButtonFormField<String>(
                  key: const Key('category_field'),
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _categoryId,
                  items: items
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _categoryId = value);
                    _syncDraft();
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<CatalogItem>>(
              future: _observablesFuture,
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Text(
                    'Catálogo de observáveis vazio — confirme sem observável se necessário.',
                  );
                }
                return DropdownButtonFormField<String>(
                  key: const Key('observable_field'),
                  decoration: const InputDecoration(
                    labelText: 'Observável',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _observableId,
                  items: items
                      .map(
                        (o) => DropdownMenuItem(
                          value: o.id,
                          child: Text(o.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _observableId = value);
                    _syncDraft();
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('note_field'),
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (_) => _syncDraft(),
            ),
            const Spacer(),
            FilledButton(
              key: const Key('confirm_button'),
              onPressed: _confirming ? null : _onConfirm,
              child: _confirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _DraftMediaSection extends StatelessWidget {
  const _DraftMediaSection({
    required this.media,
    required this.addingMedia,
    required this.onAddMedia,
    required this.onRemoveMedia,
  });

  final List<OccurrenceMediaData> media;
  final bool addingMedia;
  final VoidCallback onAddMedia;
  final ValueChanged<String> onRemoveMedia;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mídias anexadas (${media.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (media.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              key: const Key('media_grid'),
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = media[index];
                return _DraftMediaTile(
                  media: item,
                  onRemove: () => onRemoveMedia(item.id),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('add_media_button'),
          onPressed: addingMedia ? null : onAddMedia,
          icon: addingMedia
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_a_photo_outlined),
          label: Text(addingMedia ? 'Capturando...' : 'Adicionar mídia'),
        ),
      ],
    );
  }
}

class _DraftMediaTile extends StatelessWidget {
  const _DraftMediaTile({
    required this.media,
    required this.onRemove,
  });

  final OccurrenceMediaData media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 88,
            height: 88,
            child: _buildThumbnail(),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              key: Key('remove_media_${media.id}'),
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail() {
    if (media.mediaType == 'image') {
      final file = File(media.localPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.grey),
      ),
    );
  }
}
