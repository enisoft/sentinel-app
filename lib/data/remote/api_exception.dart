class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  bool get isValidation => statusCode == 422;

  bool get isServerError => statusCode >= 500;

  bool get isRetryable => isServerError || statusCode == 408;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
