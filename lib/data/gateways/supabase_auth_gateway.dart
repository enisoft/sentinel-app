import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/gateways/auth_gateway.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final SupabaseClient _client;
  String? _loginNotice;

  @override
  Stream<bool> get sessionStream =>
      _client.auth.onAuthStateChange.map((event) => event.session != null);

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  String? get loginNotice => _loginNotice;

  @override
  void clearLoginNotice() => _loginNotice = null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut({String? loginNotice}) async {
    if (loginNotice != null) {
      _loginNotice = loginNotice;
    }
    await _client.auth.signOut();
  }
}
