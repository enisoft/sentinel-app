/// Contrato de autenticação — implementação via Supabase Auth.
abstract class AuthGateway {
  Stream<bool> get sessionStream;

  bool get isSignedIn;

  String? get accessToken;

  /// Aviso one-shot para exibir na próxima tela de login (ex.: sessão expirada).
  String? get loginNotice;

  void clearLoginNotice();

  Future<void> signIn({required String email, required String password});

  Future<void> signOut({String? loginNotice});
}
