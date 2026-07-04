import '../local/app_database.dart';

/// Converte entidades locais no JSON dos endpoints de sync (contrato P3/P4).
class SyncPayloadSerializer {
  const SyncPayloadSerializer();

  Map<String, dynamic> serializeOccurrencesSyncPayload({
    required List<({Occurrence occurrence, List<OccurrenceMediaData> media})> items,
  }) {
    return {
      'occurrences': items
          .map((item) => serializeOccurrence(item.occurrence, item.media))
          .toList(),
    };
  }

  Map<String, dynamic> serializeOccurrence(
    Occurrence occurrence,
    List<OccurrenceMediaData> media,
  ) {
    return {
      'id': occurrence.id,
      'observable_id': occurrence.observableId,
      'category_id': occurrence.categoryId,
      if (occurrence.zonaId != null) 'zona_id': occurrence.zonaId,
      'title': occurrence.title,
      'description': occurrence.description,
      'status': occurrence.status,
      'priority': occurrence.priority,
      'location': occurrence.location,
      'latitude': occurrence.latitude,
      'longitude': occurrence.longitude,
      'occurred_at': toContractIso8601(occurrence.occurredAt),
      'resolved_at': occurrence.resolvedAt != null
          ? toContractIso8601(occurrence.resolvedAt!)
          : null,
      'created_at': toContractIso8601(occurrence.createdAt),
      'updated_at': occurrence.updatedAt != null
          ? toContractIso8601(occurrence.updatedAt!)
          : null,
      'media': media.map(serializeOccurrenceMedia).toList(),
    };
  }

  Map<String, dynamic> serializeOccurrenceMedia(OccurrenceMediaData media) {
    return {
      'id': media.id,
      'media_type': media.mediaType,
      'path': media.remotePath,
      'mime_type': media.mimeType,
      'original_name': media.originalName,
      'size_bytes': media.sizeBytes,
      'sort_order': media.sortOrder,
      'duration_seconds': media.durationSeconds,
      if (media.contentHash != null) 'content_hash': media.contentHash,
    };
  }

  Map<String, dynamic> serializeCheckInsSyncPayload({
    required List<CheckIn> checkIns,
  }) {
    return {
      'check_ins': checkIns.map(serializeCheckIn).toList(),
    };
  }

  Map<String, dynamic> serializeCheckIn(CheckIn checkIn) {
    return {
      'id': checkIn.id,
      'latitude': checkIn.latitude,
      'longitude': checkIn.longitude,
      'accuracy': checkIn.accuracy,
      'captured_at': toContractIso8601(checkIn.capturedAt),
      'note': checkIn.note,
    };
  }

  static String toContractIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String().replaceFirst(RegExp(r'\.\d+'), '');
  }
}
