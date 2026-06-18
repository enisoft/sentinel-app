import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/capture/occurrence_confirm_text.dart';

void main() {
  group('resolveOccurrenceConfirmText', () {
    test('uses trimmed note for title and description when present', () {
      final result = resolveOccurrenceConfirmText(note: '  Água no elevador  ');

      expect(result.title, 'Água no elevador');
      expect(result.description, 'Água no elevador');
    });

    test('defaults description by image media type when note empty', () {
      final result = resolveOccurrenceConfirmText(note: null, mediaType: 'image');

      expect(result.title, 'Ocorrência');
      expect(result.description, 'Registro fotográfico');
    });

    test('defaults description by audio media type when note blank', () {
      final result = resolveOccurrenceConfirmText(note: '   ', mediaType: 'audio');

      expect(result.title, 'Ocorrência');
      expect(result.description, 'Registro de áudio');
    });

    test('defaults description by video media type', () {
      final result = resolveOccurrenceConfirmText(mediaType: 'video');

      expect(result.description, 'Registro de vídeo');
    });

    test('falls back when media type unknown or missing', () {
      expect(
        resolveOccurrenceConfirmText(mediaType: null).description,
        'Registro de ocorrência',
      );
      expect(
        resolveOccurrenceConfirmText(mediaType: 'unknown').description,
        'Registro de ocorrência',
      );
    });
  });
}
