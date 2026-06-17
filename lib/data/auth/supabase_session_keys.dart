/// Chave estável da sessão no secure storage.
const supabaseSecureSessionKey = 'sb-session';

/// Chave legada usada pelo `SharedPreferencesLocalStorage` padrão do SDK.
String legacySharedPrefsSessionKey(String supabaseUrl) {
  final host = Uri.parse(supabaseUrl).host.split('.').first;
  return 'sb-$host-auth-token';
}
