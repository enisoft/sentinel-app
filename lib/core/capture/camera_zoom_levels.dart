/// Níveis-alvo de zoom (ENI-58): ultrawide, principal, 2x e 4x digital.
const List<double> kTargetZoomLevels = [0.5, 1.0, 2.0, 4.0];

/// Retorna apenas os níveis-alvo suportados pelo intervalo [minZoom]..[maxZoom].
///
/// Não força 0.5x sem ultrawide (`minZoom > 0.5`) nem 4x se `maxZoom < 4`.
List<double> supportedZoomLevels({
  required double minZoom,
  required double maxZoom,
}) {
  if (maxZoom < minZoom) return const [];
  return [
    for (final level in kTargetZoomLevels)
      if (level >= minZoom && level <= maxZoom) level,
  ];
}

/// Nível inicial da sessão: 1x se disponível, senão o mais próximo de 1x.
double defaultZoomLevel(List<double> levels) {
  if (levels.isEmpty) return 1.0;
  if (levels.contains(1.0)) return 1.0;
  return levels.reduce(
    (a, b) => (a - 1.0).abs() <= (b - 1.0).abs() ? a : b,
  );
}

/// Rótulo de UI: `0.5x`, `1x`, `2x`, `4x`.
String formatZoomLevelLabel(double level) {
  if (level == level.roundToDouble()) {
    return '${level.toInt()}x';
  }
  // Evita "0.50x" por imprecisão de ponto flutuante.
  final fixed = level.toStringAsFixed(1);
  final trimmed =
      fixed.endsWith('0') ? fixed.substring(0, fixed.length - 2) : fixed;
  return '${trimmed}x';
}

/// Sessão de zoom por níveis — persiste o nível ativo entre capturas.
class CameraZoomSession {
  CameraZoomSession({
    required double minZoom,
    required double maxZoom,
    required Future<void> Function(double zoom) applyZoom,
  })  : _applyZoom = applyZoom,
        levels = supportedZoomLevels(minZoom: minZoom, maxZoom: maxZoom),
        selectedLevel = defaultZoomLevel(
          supportedZoomLevels(minZoom: minZoom, maxZoom: maxZoom),
        );

  final Future<void> Function(double zoom) _applyZoom;

  /// Níveis expostos na UI (subconjunto de [kTargetZoomLevels]).
  final List<double> levels;

  /// Nível ativo na sessão de captura.
  double selectedLevel;

  /// Aplica o nível padrão no hardware (chamado uma vez ao abrir o preview).
  Future<void> applyInitial() async {
    if (levels.isEmpty) return;
    await _applyZoom(selectedLevel);
  }

  /// Troca instantânea de nível; no-op se inválido ou já selecionado.
  Future<void> select(double level) async {
    if (!levels.contains(level) || level == selectedLevel) return;
    selectedLevel = level;
    await _applyZoom(level);
  }
}
