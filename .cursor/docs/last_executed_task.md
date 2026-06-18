# Última tarefa executada — Fix 401 bootstrap (alg mismatch) + UI loading

Pedido: corrigir 401 no bootstrap (JWT alg mismatch ES256) e tratamento de 401 que travava/piscava a UI.

Data: 2026-06-17

## O que foi feito

### Fix 1 — Backend: JWT alg mismatch (env)

GoTrue local emite **ES256**; backend com `SUPABASE_JWT_ALGO=HS256` rejeitava tokens válidos → 401 em `/me`.

- **`sentinel-backend/.env`** — já configurado `SUPABASE_JWT_ALGO=ES256` (middleware `SupabaseJwtVerifier` valida via JWKS).
- Nenhuma alteração de código backend; suíte PHPUnit permanece verde com `HS256` em `phpunit.xml` (tokens de teste).

### Fix 2 — App: robustez de UI em 401

- **`lib/presentation/bootstrap/app_bootstrap_screen.dart`**
  - `finally` garante `_loading = false` em **qualquer** saída (sucesso, 401, erro).
  - 401 em `/me` → `signOut(loginNotice: …)` com mensagem amigável.
  - Se `!isSignedIn`, renderiza `SizedBox.shrink()` (evita flash de spinner/erro durante transição ao login).
- **`lib/domain/gateways/auth_gateway.dart`** + implementações — `loginNotice`, `clearLoginNotice()`, `signOut({loginNotice})`.
- **`lib/core/auth/auth_messages.dart`** — `AuthMessages.sessionExpired`.
- **`lib/presentation/auth/login_screen.dart`** — exibe `loginNotice` ao montar (one-shot).
- **`lib/data/services/occurrence_sync_service.dart`** — 401 no sync também passa `loginNotice` no signOut.
- **`lib/data/remote/api_client.dart`** — timeout 30s (configurável); `TimeoutException` → `ApiException(408, …)`.

## Testes

### App (`flutter test`)

```
00:05 +52: All tests passed!
```

Novos/alterados:

| Arquivo | Casos |
|---------|-------|
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | 401 `/me` → login + mensagem; bootstrap OK → `capture_button` |
| `test/data/remote/api_client_test.dart` | timeout → 408 |
| `test/data/services/occurrence_sync_service_test.dart` | 401 → `loginNotice` |

### Backend (`php artisan test`)

```
{"tool":"phpunit","result":"passed","tests":47,"passed":47,"assertions":164,"duration_ms":2159}
```

Sem novo teste de código (fix é env `SUPABASE_JWT_ALGO=ES256`).

## Verificação manual G65 (pendente — colar saída real)

### 1. Login + bootstrap com ES256

Pré-requisito: backend com `SUPABASE_JWT_ALGO=ES256`, Supabase local rodando, `.env` do app com IP LAN.

```
# Esperado: login → /me 200 → home/captura (sem spinner eterno, sem pisca)
```

**Saída real:** _(pendente)_

### 2. Captura → sync → Postgres

```sql
SELECT o.id, o.reported_by, o.title, o.synced_at,
       om.id AS media_id, om.path
FROM occurrences o
LEFT JOIN occurrence_media om ON om.occurrence_id = o.id
WHERE o.id = '<uuid-da-ocorrencia>'
ORDER BY om.sort_order;
```

**Esperado:** `reported_by` = uid do operador; `om.path` = `occurrences/{id}/{media_id}.jpg`.

**Saída real:** _(pendente)_

### 3. 401 forçado → mensagem + login limpo

```
# Esperado: "Sessão expirada, faça login de novo." — sem travar, sem loop
```

**Saída real:** _(pendente)_

## Arquivos tocados

| Arquivo | Ação |
|---------|------|
| `lib/core/auth/auth_messages.dart` | novo |
| `lib/domain/gateways/auth_gateway.dart` | `loginNotice` + `signOut({loginNotice})` |
| `lib/data/gateways/supabase_auth_gateway.dart` | implementação |
| `lib/data/fakes/fake_auth_gateway.dart` | implementação |
| `lib/app/di.dart` | stub `_UnimplementedAuthGateway` |
| `lib/presentation/bootstrap/app_bootstrap_screen.dart` | finally + 401 limpo + shrink |
| `lib/presentation/auth/login_screen.dart` | exibe `loginNotice` |
| `lib/data/services/occurrence_sync_service.dart` | 401 → `loginNotice` |
| `lib/data/remote/api_client.dart` | timeout HTTP |
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | novo |
| `test/data/remote/api_client_test.dart` | timeout |
| `test/data/services/occurrence_sync_service_test.dart` | assert `loginNotice` |
| `.cursor/docs/last_executed_task.md` | este relatório |

## Fora de escopo (mantido)

TUS, FGS, alteração de contrato SyncGateway além do 401, auditoria formal.

---

<details>
<summary>Histórico — ENI-28 / diagnóstico loading infinito</summary>

Ver commits anteriores e seção de diagnóstico abaixo neste arquivo.

### Diagnóstico loading infinito ENI-28 (investigação read-only)

**Causa identificada:** 401 da API REST no bootstrap → `signOut()` automático. Spinner eterno: early-return 401 sem `_loading = false`. **Corrigido nesta tarefa.**

**Âncoras originais:** `app_bootstrap_screen.dart:50-53`, `occurrence_sync_service.dart:81-88`.

</details>
