/// Contrato da fronteira de rede — implementação na fase de upload/sync HTTP.
abstract class SyncGateway {
  Future<void> uploadOccurrenceMedia({required String occurrenceId});

  Future<List<String>> syncOccurrences({required List<String> occurrenceIds});

  Future<List<String>> syncCheckIns({required List<String> checkInIds});
}
