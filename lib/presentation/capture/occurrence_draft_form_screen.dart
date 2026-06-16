import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../data/services/capture_occurrence_service.dart';

/// Form mínimo pós-captura — nunca bloqueia o disparo anterior.
class OccurrenceDraftFormScreen extends StatefulWidget {
  const OccurrenceDraftFormScreen({
    super.key,
    required this.occurrenceId,
    this.captureService,
  });

  final String occurrenceId;
  final CaptureOccurrenceService? captureService;

  @override
  State<OccurrenceDraftFormScreen> createState() =>
      _OccurrenceDraftFormScreenState();
}

class _OccurrenceDraftFormScreenState extends State<OccurrenceDraftFormScreen> {
  final _categoryController = TextEditingController();
  final _observableController = TextEditingController();
  final _noteController = TextEditingController();
  bool _confirming = false;

  CaptureOccurrenceService get _captureService =>
      widget.captureService ?? getIt<CaptureOccurrenceService>();

  @override
  void dispose() {
    _categoryController.dispose();
    _observableController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);

    try {
      await _captureService.confirmDraft(
        occurrenceId: widget.occurrenceId,
        categoryId: _emptyToNull(_categoryController.text),
        observableId: _emptyToNull(_observableController.text),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('category_field'),
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Categoria (ID)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _captureService.updateDraftForm(
                occurrenceId: widget.occurrenceId,
                categoryId: _emptyToNull(_categoryController.text),
                observableId: _emptyToNull(_observableController.text),
                note: _emptyToNull(_noteController.text),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('observable_field'),
              controller: _observableController,
              decoration: const InputDecoration(
                labelText: 'Observável (ID)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _captureService.updateDraftForm(
                occurrenceId: widget.occurrenceId,
                categoryId: _emptyToNull(_categoryController.text),
                observableId: _emptyToNull(_observableController.text),
                note: _emptyToNull(_noteController.text),
              ),
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
              onChanged: (_) => _captureService.updateDraftForm(
                occurrenceId: widget.occurrenceId,
                categoryId: _emptyToNull(_categoryController.text),
                observableId: _emptyToNull(_observableController.text),
                note: _emptyToNull(_noteController.text),
              ),
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
    );
  }
}
