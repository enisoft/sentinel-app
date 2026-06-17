/// Contrato de autenticação — implementação via Supabase Auth.
abstract class AuthGateway {
  Stream<bool> get sessionStream;

  bool get isSignedIn;

  String? get accessToken;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}
