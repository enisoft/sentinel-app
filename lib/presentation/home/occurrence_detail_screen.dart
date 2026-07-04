import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/capture/video_recording_policy.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/occurrence_repository.dart';
import '../../data/repositories/operator_profile_repository.dart';
import 'occurrences_tab.dart';

/// Detalhes read-only de ocorrência confirmada (ENI-78).
class OccurrenceDetailScreen extends StatefulWidget {
  const OccurrenceDetailScreen({
    super.key,
    required this.occurrenceId,
    this.occurrenceRepository,
    this.catalogRepository,
    this.operatorProfileRepository,
  });

  final String occurrenceId;
  final OccurrenceRepository? occurrenceRepository;
  final CatalogRepository? catalogRepository;
  final OperatorProfileRepository? operatorProfileRepository;

  @override
  State<OccurrenceDetailScreen> createState() => _OccurrenceDetailScreenState();
}

class _OccurrenceDetailScreenState extends State<OccurrenceDetailScreen> {
  Occurrence? _occurrence;
  List<OccurrenceMediaData> _media = const [];
  String? _categoryName;
  String? _observableName;
  String? _zoneName;
  bool _loading = true;

  OccurrenceRepository get _occurrenceRepo =>
      widget.occurrenceRepository ?? getIt<OccurrenceRepository>();

  CatalogRepository get _catalog =>
      widget.catalogRepository ?? getIt<CatalogRepository>();

  OperatorProfileRepository get _profileRepo =>
      widget.operatorProfileRepository ?? getIt<OperatorProfileRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final occurrence = await _occurrenceRepo.getById(widget.occurrenceId);
    if (occurrence == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final media = await _occurrenceRepo.getMedia(widget.occurrenceId);
    final categories = await _catalog.getCategories();
    final observables = await _catalog.getObservables();
    final profile = await _profileRepo.getCached();

    String? categoryName;
    if (occurrence.categoryId != null) {
      for (final c in categories) {
        if (c.id == occurrence.categoryId) {
          categoryName = c.name;
          break;
        }
      }
    }

    String? observableName;
    if (occurrence.observableId != null) {
      for (final o in observables) {
        if (o.id == occurrence.observableId) {
          observableName = o.name;
          break;
        }
      }
    }

    String? zoneName;
    if (occurrence.zonaId != null && profile != null) {
      for (final z in profile.zones) {
        if (z.id == occurrence.zonaId) {
          zoneName = z.nome;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _occurrence = occurrence;
      _media = media;
      _categoryName = categoryName;
      _observableName = observableName;
      _zoneName = zoneName;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da ocorrência'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _occurrence == null
              ? const Center(child: Text('Ocorrência não encontrada'))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ReadOnlyMediaSection(media: _media),
                        const SizedBox(height: 16),
                        _DetailField(
                          label: 'Estado',
                          value: occurrenceListStatusLabel(_occurrence!),
                        ),
                        _DetailField(
                          label: 'Data/hora',
                          value: _formatOccurredAt(_occurrence!.occurredAt),
                        ),
                        if (_zoneName != null)
                          _DetailField(label: 'Zona', value: _zoneName!),
                        if (_categoryName != null)
                          _DetailField(
                            label: 'Categoria',
                            value: _categoryName!,
                          ),
                        if (_observableName != null)
                          _DetailField(
                            label: 'Observável',
                            value: _observableName!,
                          ),
                        if (_occurrence!.description.trim().isNotEmpty)
                          _DetailField(
                            label: 'Nota',
                            value: _occurrence!.description.trim(),
                          ),
                        _DetailField(
                          label: 'ID',
                          value: occurrenceShortId(_occurrence!.id),
                        ),
                      ],
                    ),
                  ),
                ),
    );
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
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyMediaSection extends StatelessWidget {
  const _ReadOnlyMediaSection({required this.media});

  final List<OccurrenceMediaData> media;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mídias (${media.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (media.isEmpty)
          Text(
            'Nenhuma mídia anexada',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              key: const Key('detail_media_grid'),
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _ReadOnlyMediaTile(media: media[index]);
              },
            ),
          ),
      ],
    );
  }
}

class _ReadOnlyMediaTile extends StatelessWidget {
  const _ReadOnlyMediaTile({required this.media});

  final OccurrenceMediaData media;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 88,
        height: 88,
        child: _buildThumbnail(),
      ),
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
            child: Icon(Icons.videocam, color: Colors.white70, size: 32),
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
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.grey),
      ),
    );
  }
}
