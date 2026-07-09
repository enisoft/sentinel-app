import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../data/remote/api_exception.dart';

/// Falha de rede/timeout no primeiro contato com o servidor (ENI-105).
bool isInitialContactRetryable(Object error) {
  if (error is ApiException) return error.isNetworkError;
  if (error is SocketException) return true;
  if (error is http.ClientException) return true;
  if (error is TimeoutException) return true;
  return false;
}

/// Tenta [action] uma vez; em falha retryável aguarda [backoff] e tenta de novo.
Future<T> withInitialContactRetry<T>(
  Future<T> Function() action, {
  required Duration backoff,
}) async {
  try {
    return await action();
  } on Object catch (first) {
    if (!isInitialContactRetryable(first)) rethrow;
    await Future<void>.delayed(backoff);
    return action();
  }
}
