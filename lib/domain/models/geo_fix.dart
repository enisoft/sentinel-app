/// Leitura pontual de posição (check-in ou carimbo na captura).
class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;
}
