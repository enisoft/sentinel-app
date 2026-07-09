import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:tus_client_dart/tus_client_dart.dart';

/// [TusClient] com [HttpClient.idleTimeout] e abort explícito do socket (ENI-105).
///
/// O `idleTimeout` do `dart:io` fecha conexões sem tráfego de bytes — cobre
/// half-open onde `client.send()` pendura sem exceção. Complementa o
/// [TusUploadStallGuard] (timer por callback `onProgress`).
class SentinelTusClient extends TusClient {
  SentinelTusClient(
    super.file, {
    required Duration stallTimeout,
    super.store,
    super.maxChunkSize,
    super.retries,
    super.retryInterval,
    super.retryScale,
  }) : _stallTimeout = stallTimeout;

  final Duration _stallTimeout;
  HttpClient? _httpClient;
  IOClient? _ioClient;

  @override
  http.Client getHttpClient() {
    _httpClient ??= HttpClient()..idleTimeout = _stallTimeout;
    _ioClient ??= IOClient(_httpClient!);
    return _ioClient!;
  }

  /// Fecha o socket subjacente para desbloquear `send()` pendurado.
  void abort() {
    _ioClient?.close();
    _ioClient = null;
    _httpClient?.close(force: true);
    _httpClient = null;
  }
}
