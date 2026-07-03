import 'package:path/path.dart' as p;

/// Mapeia extensão do arquivo capturado para MIME type de vídeo.
String mimeTypeFromCapturePath(String path) {
  final ext = p.extension(path).toLowerCase();
  return switch (ext) {
    '.mp4' => 'video/mp4',
    '.mov' => 'video/quicktime',
    _ => 'video/mp4',
  };
}
