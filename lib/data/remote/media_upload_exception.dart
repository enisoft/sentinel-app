/// Falha no upload de mídia (TUS / Storage).
class MediaUploadException implements Exception {
  MediaUploadException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  bool get isNetworkError => statusCode == null;

  @override
  String toString() => 'MediaUploadException($statusCode): $message';
}
