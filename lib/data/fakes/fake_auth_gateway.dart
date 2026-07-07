import 'dart:async';

import '../../core/network/network_reachability.dart';
import '../../domain/gateways/auth_gateway.dart';
import 'fake_network_reachability.dart';

/// Auth fake para testes — token fixo, sem Supabase.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    this.token = 'test-jwt',
    bool signedIn = true,
    bool persistedSession = true,
    NetworkReachability? networkReachability,
  })  : _signedIn = signedIn,
        _persistedSession = persistedSession,
        _canAccessApp = signedIn || persistedSession,
        _network = networkReachability ?? FakeNetworkReachability(online: true);

  bool _signedIn;
  bool _persistedSession;
  bool _canAccessApp;
  bool _manualSignOut = false;
  final String token;
  String? _loginNotice;

  final _sessionController = StreamController<bool>.broadcast();
  final _appAccessController = StreamController<bool>.broadcast();
  final NetworkReachability _network;

  FakeNetworkReachability get network => _network as FakeNetworkReachability;

  bool refreshSucceeds = true;

  @override
  Stream<bool> get sessionStream => _sessionController.stream;

  @override
  Stream<bool> get appAccessStream async* {
    yield _canAccessApp;
    yield* _appAccessController.stream;
  }

  @override
  bool get canAccessApp => _canAccessApp;

  @override
  bool get isSignedIn => _signedIn;

  @override
  String? get accessToken => _signedIn ? token : null;

  @override
  String? get loginNotice => _loginNotice;

  @override
  void clearLoginNotice() => _loginNotice = null;

  @override
  Future<bool> hasPersistedSession() async {
    if (_manualSignOut) return false;
    return _persistedSession;
  }

  @override
  Future<bool> tryRefreshSessionSilently() async {
    if (!await hasPersistedSession() || !refreshSucceeds) return false;
    _signedIn = true;
    _sessionController.add(true);
    await _setAppAccess(true);
    return true;
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

  /// Simula refresh offline falho: sessão Supabase null, Keystore intacto.
  void simulateOfflineSessionLoss() {
    _signedIn = false;
    _sessionController.add(false);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _manualSignOut = false;
    _signedIn = true;
    _persistedSession = true;
    _sessionController.add(true);
    await _setAppAccess(true);
  }

  @override
  Future<void> signOut({String? loginNotice}) async {
    if (loginNotice != null) {
      _loginNotice = loginNotice;
    }
    _manualSignOut = true;
    _signedIn = false;
    _persistedSession = false;
    _sessionController.add(false);
    await _setAppAccess(false);
  }

  Future<void> _setAppAccess(bool value) async {
    _canAccessApp = value;
    if (!_appAccessController.isClosed) {
      _appAccessController.add(value);
    }
  }

  void dispose() {
    unawaited(_sessionController.close());
    unawaited(_appAccessController.close());
  }
}
