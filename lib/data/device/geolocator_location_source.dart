import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/models/geo_fix.dart';
import '../../domain/services/location_source.dart';

/// GPS em primeiro plano com timeout e degradação graciosa.
class GeolocatorLocationSource implements LocationSource {
  GeolocatorLocationSource({
    this.timeout = const Duration(seconds: 8),
  });

  final Duration timeout;

  @override
  Future<GeoFix?> getCurrentPosition() async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) {
      return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return GeoFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        capturedAt: position.timestamp.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }
}
