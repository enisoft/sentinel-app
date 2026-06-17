class OperatorProfile {
  const OperatorProfile({
    required this.id,
    required this.name,
    required this.role,
    this.municipalityId,
    this.photoPath,
  });

  final String id;
  final String name;
  final String role;
  final String? municipalityId;
  final String? photoPath;

  factory OperatorProfile.fromJson(Map<String, dynamic> json) {
    return OperatorProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      municipalityId: json['municipality_id'] as String?,
      photoPath: json['photo_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'municipality_id': municipalityId,
        'photo_path': photoPath,
      };
}
