class CatalogDeltaResponse {
  const CatalogDeltaResponse({
    required this.serverTime,
    required this.items,
    required this.deletedIds,
    this.updatedSince,
  });

  final String? updatedSince;
  final String serverTime;
  final List<Map<String, dynamic>> items;
  final List<String> deletedIds;

  factory CatalogDeltaResponse.fromJson(Map<String, dynamic> json) {
    return CatalogDeltaResponse(
      updatedSince: json['updated_since'] as String?,
      serverTime: json['server_time'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      deletedIds: (json['deleted_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}
