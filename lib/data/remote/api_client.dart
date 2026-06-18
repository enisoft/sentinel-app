import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../../domain/models/operator_profile.dart';
import 'api_exception.dart';
import 'catalog_delta_response.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required AuthGateway authGateway,
    http.Client? httpClient,
    Duration requestTimeout = const Duration(seconds: 30),
  })  : _baseUrl = config.apiBaseUrl,
        _auth = authGateway,
        _http = httpClient ?? http.Client(),
        _requestTimeout = requestTimeout;

  final String _baseUrl;
  final AuthGateway _auth;
  final http.Client _http;
  final Duration _requestTimeout;

  Future<OperatorProfile> getMe() async {
    final response = await _get('/me');
    return OperatorProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CatalogDeltaResponse> getCatalogObservables({String? updatedSince}) =>
      _getCatalog('observables', updatedSince);

  Future<CatalogDeltaResponse> getCatalogCategories({String? updatedSince}) =>
      _getCatalog('categories', updatedSince);

  Future<CatalogDeltaResponse> getCatalogMunicipalities({String? updatedSince}) =>
      _getCatalog('municipalities', updatedSince);

  Future<List<String>> postOccurrencesSync(Map<String, dynamic> body) async {
    final response = await _post('/occurrences/sync', body);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return (data['ids'] as List<dynamic>).cast<String>();
  }

  Future<CatalogDeltaResponse> _getCatalog(
    String entity,
    String? updatedSince,
  ) async {
    final query = updatedSince != null
        ? '?updated_since=${Uri.encodeQueryComponent(updatedSince)}'
        : '';
    final response = await _get('/catalog/$entity$query');
    return CatalogDeltaResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<http.Response> _get(String path) {
    return _authorizedRequest(
      (uri, headers) => _http.get(uri, headers: headers),
      path,
    );
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return _authorizedRequest(
      (uri, headers) => _http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
      path,
      extraHeaders: const {'Content-Type': 'application/json'},
    );
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Uri uri, Map<String, String> headers) send,
    String path, {
    Map<String, String> extraHeaders = const {},
  }) async {
    final token = _auth.accessToken;
    if (token == null) {
      throw ApiException(401, 'Token de autenticação ausente.');
    }

    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      ...extraHeaders,
    };

    http.Response response;
    try {
      response = await send(uri, headers).timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException(408, 'Tempo esgotado na comunicação com o servidor.');
    }

    if (response.statusCode == 401) {
      throw ApiException(401, _extractMessage(response));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _extractMessage(response));
    }

    return response;
  }

  String _extractMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] as String? ?? response.body;
    } on Object {
      return response.body;
    }
  }
}
