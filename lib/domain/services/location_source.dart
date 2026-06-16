import '../models/geo_fix.dart';

/// Contrato de geolocalização em primeiro plano — implementação real na fase device.
abstract class LocationSource {
  Future<GeoFix> getCurrentPosition();
}
