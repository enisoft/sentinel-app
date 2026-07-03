import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../data/remote/api_exception.dart';
import '../../data/remote/media_upload_exception.dart';

/// Indica falha de rede/conectividade durante sync (ENI-38 / ENI-42).
bool isSyncNetworkError(Object error) {
  if (error is ApiException) return error.isNetworkError;
  if (error is SocketException) return true;
  if (error is http.ClientException) return true;
  if (error is TimeoutException) return true;
  if (error is MediaUploadException) {
    return error.isNetworkError;
  }
  return false;
}
