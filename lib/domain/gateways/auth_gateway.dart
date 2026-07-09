import '../../core/auth/silent_refresh_result.dart';

/// Contrato de autenticação — implementação via Supabase Auth.
abstract class AuthGateway {
  /// Sessão Supabase ativa em memória (JWT válido ou refresh recente).
  Stream<bool> get sessionStream;

  /// Operador pode usar o app (captura) — inclui sessão offline no Keystore (ENI-84).
  Stream<bool> get appAccessStream;

  bool get canAccessApp;

  bool get isSignedIn;

  String? get accessToken;

  /// UID do operador logado (claim `sub` / id do `/me`). Null sem sessão.
  String? get currentUserId;

  /// Aviso one-shot para exibir na próxima tela de login (ex.: sessão expirada).
  String? get loginNotice;

  void clearLoginNotice();

  /// Credenciais de login prévio persistidas no secure storage (ENI-33).
  Future<bool> hasPersistedSession();

  /// Tenta renovar JWT silenciosamente (ex.: ao reconectar).
  Future<SilentRefreshResult> tryRefreshSessionSilently();

  /// `true` apenas para 401 real online após tentativa de refresh (ENI-84).
  Future<bool> shouldSignOutForUnauthorized({
    required int? statusCode,
    bool isNetworkError = false,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut({String? loginNotice});
}
