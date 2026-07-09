import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gotrue/gotrue.dart' show AuthRetryableFetchException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/silent_refresh_result.dart';
import '../../core/network/network_reachability.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../auth/secure_key_value_store.dart';
import '../auth/supabase_session_keys.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(
    this._client,
    this._sessionStore, {
    NetworkReachability? networkReachability,
    Duration? refreshTimeout,
  })  : _network = networkReachability ?? DnsNetworkReachability(),
        _refreshTimeout = refreshTimeout ?? const Duration(seconds: 10) {
    _canAccessApp = _client.auth.currentSession != null;
    _sessionSubscription = _client.auth.onAuthStateChange.listen(
      (event) => unawaited(_onAuthStateChange(event)),
    );
    unawaited(_seedAppAccess());
  }

  final SupabaseClient _client;
  final SecureKeyValueStore _sessionStore;
  final NetworkReachability _network;
  final Duration _refreshTimeout;

  String? _loginNotice;
  bool _manualSignOut = false;
  bool _canAccessApp = false;

  final _appAccessController = StreamController<bool>.broadcast();
  StreamSubscription<AuthState>? _sessionSubscription;

  @override
  Stream<bool> get sessionStream =>
      _client.auth.onAuthStateChange.map((event) => event.session != null);

  @override
  Stream<bool> get appAccessStream async* {
    yield _canAccessApp;
    yield* _appAccessController.stream;
  }

  @override
  bool get canAccessApp => _canAccessApp;

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String? get loginNotice => _loginNotice;

  @override
  void clearLoginNotice() => _loginNotice = null;

  @override
  Future<bool> hasPersistedSession() async {
    if (_manualSignOut) return false;
    return _sessionStore.containsKey(supabaseSecureSessionKey);
  }

  @override
  Future<SilentRefreshResult> tryRefreshSessionSilently() async {
    if (!await hasPersistedSession()) {
      return const SilentRefreshResult(refreshed: false);
    }
    try {
      final result = await _client.auth.refreshSession().timeout(_refreshTimeout);
      final ok = result.session != null;
      if (ok) {
        _manualSignOut = false;
        await _setAppAccess(true);
      }
      return SilentRefreshResult(refreshed: ok);
    } on TimeoutException {
      return const SilentRefreshResult(
        refreshed: false,
        serverUnreachable: true,
      );
    } on Object catch (error) {
      return SilentRefreshResult(
        refreshed: false,
        serverUnreachable: _isRefreshNetworkFailure(error),
      );
    }
  }

  static bool _isRefreshNetworkFailure(Object error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    if (error is AuthRetryableFetchException) return true;
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('connection') ||
        message.contains('network');
  }

  @visibleForTesting
  static bool isRefreshNetworkFailureForTest(Object error) =>
      _isRefreshNetworkFailure(error);

  @override
  Future<bool> shouldSignOutForUnauthorized({
    required int? statusCode,
    bool isNetworkError = false,
  }) async {
    if (isNetworkError || statusCode != 401) return false;
    final refreshed = await tryRefreshSessionSilently();
    if (refreshed.refreshed) return false;
    if (!await _network.isOnline()) return false;
    return true;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _manualSignOut = false;
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut({String? loginNotice}) async {
    if (loginNotice != null) {
      _loginNotice = loginNotice;
    }
    _manualSignOut = true;
    await _setAppAccess(false);
    await _client.auth.signOut();
  }

  Future<void> _seedAppAccess() async {
    if (_client.auth.currentSession != null) {
      await _setAppAccess(true);
      return;
    }
    if (await hasPersistedSession()) {
      await _setAppAccess(true);
      return;
    }
    await _setAppAccess(false);
  }

  Future<void> _onAuthStateChange(AuthState event) async {
    if (event.session != null) {
      _manualSignOut = false;
      await _setAppAccess(true);
      return;
    }
    if (_manualSignOut) {
      await _setAppAccess(false);
      return;
    }
    if (await hasPersistedSession()) {
      await _setAppAccess(true);
      return;
    }
    await _setAppAccess(false);
  }

  Future<void> _setAppAccess(bool value) async {
    _canAccessApp = value;
    if (!_appAccessController.isClosed) {
      _appAccessController.add(value);
    }
  }

  void dispose() {
    unawaited(_sessionSubscription?.cancel());
    unawaited(_appAccessController.close());
  }
}
