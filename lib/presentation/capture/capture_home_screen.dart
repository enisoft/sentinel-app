import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../data/services/capture_occurrence_service.dart';
import 'occurrence_draft_form_screen.dart';

/// Home capture-first: placeholder de câmera que dispara captura via fake/device.
class CaptureHomeScreen extends StatefulWidget {
  const CaptureHomeScreen({super.key, this.captureService});

  final CaptureOccurrenceService? captureService;

  @override
  State<CaptureHomeScreen> createState() => _CaptureHomeScreenState();
}

class _CaptureHomeScreenState extends State<CaptureHomeScreen> {
  bool _capturing = false;

  CaptureOccurrenceService get _captureService =>
      widget.captureService ?? getIt<CaptureOccurrenceService>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: Icon(Icons.photo_camera_outlined, size: 96, color: Colors.white24),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Column(
                children: [
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
