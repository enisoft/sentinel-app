import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/services/capture_occurrence_service.dart';

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
  String? _categoryId;
  String? _observableId;
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
