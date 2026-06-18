/// Contrato de upload de mídia para Storage — implementação TUS na camada data.
abstract class MediaUploader {
  /// Sobe todas as mídias pendentes da ocorrência (`remote_path` null).
  /// Define `remote_path` canônico após cada upload OK.
  /// Lança em falha (401, rede, TUS) — orquestrador trata `failed_phase`.
  Future<void> uploadOccurrenceMedia({required String occurrenceId});
}
