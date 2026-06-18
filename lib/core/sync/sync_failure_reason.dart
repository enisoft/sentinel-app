/// Convenções de `failed_reason` na fila de sync.
abstract final class SyncFailureReason {
  static const validationPrefix = 'validation:';

  static bool isNonRetryableValidation(String? failedReason) =>
      failedReason?.startsWith(validationPrefix) ?? false;
}
