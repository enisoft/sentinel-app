import '../models/geo_fix.dart';

/// Contrato de geolocalização em primeiro plano — implementação real na fase device.
abstract class LocationSource {
  /// Retorna fix GPS ou `null` se permissão negada, timeout ou serviço indisponível.
  Future<GeoFix?> getCurrentPosition();
}
