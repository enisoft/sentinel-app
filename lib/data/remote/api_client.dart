import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/network/initial_contact_retry.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../../domain/models/operator_profile.dart';
import 'api_exception.dart';
import 'catalog_delta_response.dart';
import 'messages_list_response.dart';
import '../../domain/models/inbox_message.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required AuthGateway authGateway,
    http.Client? httpClient,
    Duration? requestTimeout,
    Duration? initialContactTimeout,
    Duration? initialContactRetryBackoff,
  })  : _baseUrl = config.apiBaseUrl,
        _auth = authGateway,
        _http = httpClient ?? http.Client(),
        _requestTimeout = requestTimeout ?? const Duration(seconds: 30),
        _initialContactTimeout = initialContactTimeout ??
            Duration(seconds: config.syncInitialContactTimeoutSeconds),
        _initialContactRetryBackoff = initialContactRetryBackoff ??
            Duration(seconds: config.syncInitialContactRetryBackoffSeconds);

  final String _baseUrl;
  final AuthGateway _auth;
  final http.Client _http;
  final Duration _requestTimeout;
  final Duration _initialContactTimeout;
  final Duration _initialContactRetryBackoff;

  Future<OperatorProfile> getMe({bool useInitialContactRetry = true}) {
    Future<OperatorProfile> fetch() async {
      final response = await _get('/me', timeout: _initialContactTimeout);
      return OperatorProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    if (!useInitialContactRetry) return fetch();

    return withInitialContactRetry(
      fetch,
      backoff: _initialContactRetryBackoff,
    );
  }

  Future<CatalogDeltaResponse> getCatalogObservables({String? updatedSince}) =>
      _getCatalog('observables', updatedSince);

  Future<CatalogDeltaResponse> getCatalogCategories({String? updatedSince}) =>
      _getCatalog('categories', updatedSince);

  Future<CatalogDeltaResponse> getCatalogMunicipalities({String? updatedSince}) =>
      _getCatalog('municipalities', updatedSince);

  Future<CatalogDeltaResponse> getCatalogZones({String? updatedSince}) =>
      _getCatalog('zones', updatedSince);

  Future<List<InboxMessage>> getMessages() async {
    final response = await _get('/messages');
    return MessagesListResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    ).items;
  }

  Future<InboxMessage> postMessageRead(String messageId) =>
      _postMessageAction(messageId, 'read');

  Future<InboxMessage> postMessageAccept(String messageId) =>
      _postMessageAction(messageId, 'accept');

  Future<InboxMessage> postMessageComplete(String messageId) =>
      _postMessageAction(messageId, 'complete');

  Future<InboxMessage> postMessageReject(String messageId) =>
      _postMessageAction(messageId, 'reject');

  Future<InboxMessage> _postMessageAction(
    String messageId,
    String action,
  ) async {
    final response = await _post('/messages/$messageId/$action', const {});
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
    return InboxMessage.fromJson(data);
  }

  Future<List<String>> postOccurrencesSync(Map<String, dynamic> body) {
    return withInitialContactRetry(
      () async {
        final response = await _post(
          '/occurrences/sync',
          body,
          timeout: _initialContactTimeout,
        );
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>;
        return (data['ids'] as List<dynamic>).cast<String>();
      },
      backoff: _initialContactRetryBackoff,
    );
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

  Future<http.Response> _get(String path, {Duration? timeout}) {
    return _authorizedRequest(
      (uri, headers) => _http.get(uri, headers: headers),
      path,
      timeout: timeout,
    );
  }

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) {
    return _authorizedRequest(
      (uri, headers) => _http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
      path,
      extraHeaders: const {'Content-Type': 'application/json'},
      timeout: timeout,
    );
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Uri uri, Map<String, String> headers) send,
    String path, {
    Map<String, String> extraHeaders = const {},
    Duration? timeout,
  }) async {
    final token = _auth.accessToken;
    if (token == null) {
      if (await _auth.hasPersistedSession()) {
        throw ApiException.network('Sessão offline — token indisponível.');
      }
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
      response = await send(uri, headers).timeout(timeout ?? _requestTimeout);
    } on TimeoutException {
      throw ApiException(
        408,
        'Tempo esgotado na comunicação com o servidor.',
        isNetworkError: true,
      );
    } on SocketException catch (e) {
      throw ApiException.network(e.message);
    } on http.ClientException catch (e) {
      throw ApiException.network(e.message);
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
