import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/gateways/auth_gateway.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  Stream<bool> get sessionStream =>
      _client.auth.onAuthStateChange.map((event) => event.session != null);

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
