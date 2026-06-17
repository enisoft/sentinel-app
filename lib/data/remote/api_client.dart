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
  })  : _baseUrl = config.apiBaseUrl,
        _auth = authGateway,
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final AuthGateway _auth;
  final http.Client _http;

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

  Future<http.Response> _get(String path) async {
    final token = _auth.accessToken;
    if (token == null) {
      throw ApiException(401, 'Token de autenticação ausente.');
    }

    final uri = Uri.parse('$_baseUrl$path');
    final response = await _http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

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
