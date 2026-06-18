import '../../domain/gateways/sync_gateway.dart';
import '../local/app_database.dart';
import '../remote/api_client.dart';
import '../repositories/occurrence_repository.dart';
import '../sync/sync_payload_serializer.dart';

/// Implementação HTTP de sync — POST /occurrences/sync via [ApiClient].
class SyncGatewayHttp implements SyncGateway {
  SyncGatewayHttp({
    required ApiClient apiClient,
    required OccurrenceRepository occurrenceRepository,
    SyncPayloadSerializer serializer = const SyncPayloadSerializer(),
  })  : _api = apiClient,
        _occurrences = occurrenceRepository,
        _serializer = serializer;

  final ApiClient _api;
  final OccurrenceRepository _occurrences;
  final SyncPayloadSerializer _serializer;

  @override
  Future<void> uploadOccurrenceMedia({required String occurrenceId}) async {
    // TUS real = ENI-29; stub de path tratado pelo orquestrador.
  }

  @override
  Future<List<String>> syncOccurrences({required List<String> occurrenceIds}) async {
    final items = <({Occurrence occurrence, List<OccurrenceMediaData> media})>[];

    for (final id in occurrenceIds) {
      final occurrence = await _occurrences.getById(id);
      if (occurrence == null) continue;
      final media = await _occurrences.getMedia(id);
      items.add((occurrence: occurrence, media: media));
    }

    if (items.isEmpty) return [];

    final payload = _serializer.serializeOccurrencesSyncPayload(items: items);
    return _api.postOccurrencesSync(payload);
  }

  @override
  Future<List<String>> syncCheckIns({required List<String> checkInIds}) {
    throw UnimplementedError('syncCheckIns HTTP — fora de escopo E10.1');
  }
}
