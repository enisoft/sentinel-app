/// Resultado de uma captura de mídia (câmera in-app ou fallback galeria).
class CaptureResult {
  const CaptureResult({
    required this.localPath,
    required this.mediaType,
    required this.mimeType,
    required this.capturedAt,
    this.sizeBytes,
    this.durationSeconds,
  });

  final String localPath;
  final String mediaType;
  final String mimeType;
  final DateTime capturedAt;
  final int? sizeBytes;
  final int? durationSeconds;
}
