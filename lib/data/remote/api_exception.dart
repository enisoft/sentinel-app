class ApiException implements Exception {
  ApiException(
    this.statusCode,
    this.message, {
    bool? isNetworkError,
  }) : isNetworkError = isNetworkError ?? statusCode == 408;

  final int statusCode;
  final String message;
  final bool isNetworkError;

  factory ApiException.network(String message) =>
      ApiException(0, message, isNetworkError: true);

  bool get isUnauthorized => statusCode == 401;

  bool get isValidation => statusCode == 422;

  bool get isServerError => statusCode >= 500;

  bool get isRetryable => isNetworkError || isServerError;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
