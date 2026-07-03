/// Câmera indisponível por permissão negada ou hardware ausente.
class CameraPermissionDeniedException implements Exception {
  CameraPermissionDeniedException([this.message = 'Permissão de câmera negada.']);

  final String message;

  @override
  String toString() => message;
}
