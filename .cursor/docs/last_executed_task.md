# ENI-84 — Sessão persiste offline; captura sem rede

**Tipo:** correção auth/sessão (offline-first)  
**Data:** 2026-07-05  
**Branch:** working tree

---

## Problema

Operador logado offline (JWT expira, refresh Supabase falha) era derrubado para login e não conseguia capturar.

## Causa

- `sessionStream` do Supabase emitia não-autenticado após refresh falho → `AuthGate` ia para `LoginScreen`.
- `accessToken == null` → `ApiClient` lançava 401 local → `signOut` com "sessão expirada".

## Correção

| Peça | Mudança |
|------|---------|
| `AuthGateway` | `appAccessStream`, `canAccessApp`, `hasPersistedSession`, `tryRefreshSessionSilently`, `shouldSignOutForUnauthorized` |
| `SupabaseAuthGateway` | Mantém acesso se Keystore (`sb-session`) intacto; refresh silencioso; signOut só com 401 online após refresh falho |
| `AuthGate` | Usa `appAccessStream` em vez de `sessionStream` |
| `ApiClient` | Token ausente + sessão persistida → `ApiException.network` (não 401) |
| `TusMediaUploader` | Token ausente → `MediaUploadException` rede (não 401) |
| `AppBootstrapScreen` | Refresh no startup; signOut condicional; fallback perfil cache offline |
| `OccurrenceSyncService` | 401 só desloga online após refresh falho; offline enfileira com `hadNetworkFailure` |
| `NetworkReachability` | `DnsNetworkReachability` + `FakeNetworkReachability` para testes |

## Arquivos alterados / criados

| Arquivo | Ação |
|---------|------|
| `lib/domain/gateways/auth_gateway.dart` | modificado — contrato ENI-84 |
| `lib/data/gateways/supabase_auth_gateway.dart` | modificado — appAccess offline |
| `lib/core/network/network_reachability.dart` | **novo** |
| `lib/data/fakes/fake_network_reachability.dart` | **novo** |
| `lib/data/fakes/fake_auth_gateway.dart` | modificado — simula offline |
| `lib/presentation/auth/auth_gate.dart` | modificado — appAccessStream |
| `lib/presentation/bootstrap/app_bootstrap_screen.dart` | modificado — refresh + signOut condicional |
| `lib/data/remote/api_client.dart` | modificado — token offline = rede |
| `lib/data/remote/tus_media_uploader.dart` | modificado — upload adiado offline |
| `lib/data/services/occurrence_sync_service.dart` | modificado — 401 condicional |
| `lib/app/di.dart` | modificado — Keystore + NetworkReachability |
| `test/presentation/auth/auth_gate_offline_test.dart` | **novo** |
| `test/data/remote/api_client_test.dart` | modificado |
| `test/data/services/occurrence_sync_service_test.dart` | modificado |
| `test/data/services/capture_occurrence_service_test.dart` | modificado |
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | modificado |
| `.cursor/docs/audit_2026-07-05_eni-84.md` | **novo** |

## Testes

```
flutter test
00:08 +209: All tests passed!
```

Cobertura ENI-84:
- sessionStream null + Keystore → permanece no app
- captura com `accessToken` null
- 401 online → desloga
- 401 offline sync → não desloga
- refresh silencioso ao reconectar

## Verificação manual (pendente — G86)

1. Logar no Wi-Fi → modo avião → reabrir app → **não** cai pro login; captura OK; fila cresce.
2. Voltar rede → sync sobe; segue logado sem novo login.

## Auditoria

Ver `.cursor/docs/audit_2026-07-05_eni-84.md`.
