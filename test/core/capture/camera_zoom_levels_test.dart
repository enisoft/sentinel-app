import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/capture/camera_zoom_levels.dart';

void main() {
  group('supportedZoomLevels', () {
    test('G86 típico sem ultrawide: 1x, 2x, 4x', () {
      expect(
        supportedZoomLevels(minZoom: 1.0, maxZoom: 8.0),
        [1.0, 2.0, 4.0],
      );
    });

    test('com ultrawide: inclui 0.5x', () {
      expect(
        supportedZoomLevels(minZoom: 0.5, maxZoom: 8.0),
        [0.5, 1.0, 2.0, 4.0],
      );
    });

    test('não força 0.5x se min > 0.5', () {
      expect(
        supportedZoomLevels(minZoom: 0.6, maxZoom: 3.0),
        [1.0, 2.0],
      );
    });

    test('não inclui 4x se max < 4', () {
      expect(
        supportedZoomLevels(minZoom: 1.0, maxZoom: 2.0),
        [1.0, 2.0],
      );
    });

    test('só 1x quando range mínimo', () {
      expect(
        supportedZoomLevels(minZoom: 1.0, maxZoom: 1.0),
        [1.0],
      );
    });

    test('range inválido retorna vazio', () {
      expect(
        supportedZoomLevels(minZoom: 2.0, maxZoom: 1.0),
        isEmpty,
      );
    });
  });

  group('defaultZoomLevel', () {
    test('prefere 1x quando disponível', () {
      expect(defaultZoomLevel([0.5, 1.0, 2.0, 4.0]), 1.0);
      expect(defaultZoomLevel([1.0, 2.0]), 1.0);
    });

    test('escolhe o mais próximo de 1x quando 1x ausente', () {
      expect(defaultZoomLevel([0.5, 2.0]), 0.5);
      expect(defaultZoomLevel([2.0, 4.0]), 2.0);
    });
  });

  group('formatZoomLevelLabel', () {
    test('formata níveis-alvo', () {
      expect(formatZoomLevelLabel(0.5), '0.5x');
      expect(formatZoomLevelLabel(1.0), '1x');
      expect(formatZoomLevelLabel(2.0), '2x');
      expect(formatZoomLevelLabel(4.0), '4x');
    });
  });

  group('CameraZoomSession', () {
    test('mapeia níveis a partir de min/max do device', () {
      final session = CameraZoomSession(
        minZoom: 1.0,
        maxZoom: 8.0,
        applyZoom: (_) async {},
      );
      expect(session.levels, [1.0, 2.0, 4.0]);
      expect(session.selectedLevel, 1.0);
    });

    test('select chama setZoomLevel correspondente', () async {
      final applied = <double>[];
      final session = CameraZoomSession(
        minZoom: 0.5,
        maxZoom: 8.0,
        applyZoom: (zoom) async => applied.add(zoom),
      );

      await session.select(2.0);
      expect(session.selectedLevel, 2.0);
      expect(applied, [2.0]);

      await session.select(4.0);
      expect(session.selectedLevel, 4.0);
      expect(applied, [2.0, 4.0]);
    });

    test('select ignora nível não suportado', () async {
      final applied = <double>[];
      final session = CameraZoomSession(
        minZoom: 1.0,
        maxZoom: 2.0,
        applyZoom: (zoom) async => applied.add(zoom),
      );

      await session.select(4.0);
      expect(session.selectedLevel, 1.0);
      expect(applied, isEmpty);
    });

    test('nível ativo persiste na sessão entre seleções', () async {
      final session = CameraZoomSession(
        minZoom: 1.0,
        maxZoom: 8.0,
        applyZoom: (_) async {},
      );

      await session.select(2.0);
      expect(session.selectedLevel, 2.0);

      // Simula outro clipe na mesma sessão — nível não reseta.
      await session.select(2.0);
      expect(session.selectedLevel, 2.0);

      await session.select(4.0);
      expect(session.selectedLevel, 4.0);
    });

    test('applyInitial aplica o nível padrão', () async {
      final applied = <double>[];
      final session = CameraZoomSession(
        minZoom: 1.0,
        maxZoom: 8.0,
        applyZoom: (zoom) async => applied.add(zoom),
      );

      await session.applyInitial();
      expect(applied, [1.0]);
    });
  });
}
