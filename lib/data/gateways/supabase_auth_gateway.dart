import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/network_reachability.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../auth/secure_key_value_store.dart';
import '../auth/supabase_session_keys.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(
    this._client,
    this._sessionStore, {
    NetworkReachability? networkReachability,
  }) : _network = networkReachability ?? DnsNetworkReachability() {
    _canAccessApp = _client.auth.currentSession != null;
    _sessionSubscription = _client.auth.onAuthStateChange.listen(
      (event) => unawaited(_onAuthStateChange(event)),
    );
    unawaited(_seedAppAccess());
  }

  final SupabaseClient _client;
  final SecureKeyValueStore _sessionStore;
  final NetworkReachability _network;

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
  Future<bool> tryRefreshSessionSilently() async {
    if (!await hasPersistedSession()) return false;
    try {
      final result = await _client.auth.refreshSession();
      final ok = result.session != null;
      if (ok) {
        _manualSignOut = false;
        await _setAppAccess(true);
      }
      return ok;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> shouldSignOutForUnauthorized({
    required int? statusCode,
    bool isNetworkError = false,
  }) async {
    if (isNetworkError || statusCode != 401) return false;
    final refreshed = await tryRefreshSessionSilently();
    if (refreshed) return false;
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
