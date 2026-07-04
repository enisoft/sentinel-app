import 'operator_zone.dart';

class OperatorProfile {
  const OperatorProfile({
    required this.id,
    required this.name,
    required this.role,
    this.municipalityId,
    this.photoPath,
    this.zones = const [],
    this.defaultZoneId,
  });

  final String id;
  final String name;
  final String role;
  final String? municipalityId;
  final String? photoPath;
  final List<OperatorZone> zones;
  final String? defaultZoneId;

  factory OperatorProfile.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['zones'] as List<dynamic>? ?? const [];
    return OperatorProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      municipalityId: json['municipality_id'] as String?,
      photoPath: json['photo_path'] as String?,
      zones: zonesJson
          .map((item) => OperatorZone.fromJson(item as Map<String, dynamic>))
          .toList(),
      defaultZoneId: json['default_zone_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'municipality_id': municipalityId,
        'photo_path': photoPath,
        'zones': zones.map((z) => z.toJson()).toList(),
        'default_zone_id': defaultZoneId,
      };
}
