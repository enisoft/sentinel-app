import '../../domain/models/geo_fix.dart';
import '../../domain/services/location_source.dart';

/// GPS em memória para fase shell.
class FakeLocationSource implements LocationSource {
  FakeLocationSource({
    this.nextLatitude = -25.4284,
    this.nextLongitude = -49.2733,
    this.nextAccuracy = 8.5,
    this.returnNull = false,
    DateTime? nextCapturedAt,
  }) : _nextCapturedAt = nextCapturedAt ?? DateTime.utc(2026, 6, 15, 12, 0);

  double nextLatitude;
  double nextLongitude;
  double nextAccuracy;
  bool returnNull;
  final DateTime _nextCapturedAt;

  int positionCallCount = 0;

  @override
  Future<GeoFix?> getCurrentPosition() async {
    positionCallCount++;
    if (returnNull) return null;
    return GeoFix(
      latitude: nextLatitude,
      longitude: nextLongitude,
      accuracy: nextAccuracy,
      capturedAt: _nextCapturedAt,
    );
  }
}
