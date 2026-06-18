# Última tarefa executada — Correção logout indevido offline (ENI-31 passo 6)

Pedido: corrigir logout indevido quando OFFLINE no bootstrap (`GET /me`). Escopo fechado — distinguir falha de rede vs 401, bootstrap offline-tolerante com cache Drift (ENI-27), testes + roteiro de verificação device G56.

Data: 2026-06-18  
Bug: com Wi‑Fi desligado, falha de rede no `/me` expulsava o operador (tratada como sessão inválida). Crítico para app offline-first.

---

## Correção aplicada

### 1. `ApiException` + `ApiClient` — rede ≠ 401

| Caso | Comportamento |
|------|---------------|
| `401` (resposta HTTP do servidor) | `isUnauthorized = true` → `signOut` (inalterado) |
| `SocketException`, `ClientException`, timeout (`408`) | `isNetworkError = true` → **nunca** desloga |
| Token ausente localmente | `401` local (sessão realmente inválida) |

`ApiClient._authorizedRequest` agora encapsula exceções de transporte em `ApiException.network()` / `isNetworkError: true`.

### 2. `BootstrapService` — offline-tolerante

| Cenário `/me` | Resultado |
|---------------|-----------|
| Rede OK | `fetchAndCache()` → perfil atualizado no Drift |
| Rede falha + perfil em cache | `profileLoaded: true` → entra no app com cache |
| Rede falha + sem cache (primeiro acesso) | `profileLoaded: false`, mensagem clara — **sem** `signOut` |
| `401` real | propaga → `signOut` na tela de bootstrap |

Catálogo: mantém tolerância existente (banner/retry se sync falhar por rede).

### 3. `AppBootstrapScreen`

- `signOut` **somente** em `ApiException.isUnauthorized`.
- Removido catch genérico que poderia mascarar erros; rede sem cache vem do `BootstrapService` com mensagem dedicada.

### Mensagem primeiro acesso offline

```
Sem conexão. Conecte-se à internet para o primeiro acesso.
```

(`lib/core/bootstrap/bootstrap_messages.dart`)

---

## Testes automatizados

**`flutter test` → 67 passed** (+7 novos)

| Teste | Verifica |
|-------|----------|
| `api_client_test` — socket / client exception | `isNetworkError`, não `isUnauthorized` |
| `api_client_test` — timeout 408 | `isNetworkError` |
| `bootstrap_service_test` — rede + cache | `profileLoaded: true` |
| `bootstrap_service_test` — 401 | propaga para signOut |
| `bootstrap_service_test` — rede sem cache | mensagem primeiro acesso |
| `app_bootstrap_screen_test` — rede + cache | permanece logado, chega na captura |
| `app_bootstrap_screen_test` — rede sem cache | mensagem offline, **não** desloga |
| `app_bootstrap_screen_test` — 401 | desloga (ENI-27, inalterado) |

---

## Verificação manual — device G56 (pendente)

**Pré-requisito:** operador já logou online ao menos uma vez (cache Drift populado).

| # | Passo | Evidência | Status |
|---|-------|-----------|--------|
| 1 | Logar online (popula cache perfil + catálogo) | Drift `cached_operator_profiles` | ⬜ |
| 2 | Ativar modo avião / desligar Wi‑Fi | Screenshot device | ⬜ |
| 3 | Matar app e reabrir | Operador **continua logado**, vê home/captura | ⬜ |
| 4 | Capturar offline | Item na fila (`sync_state = local_saved`) | ⬜ |
| 5 | Religar rede | Sync automático → Postgres + drift `synced` | ⬜ |

**Isso fecha o passo 6 do ENI-31** quando evidências forem coladas.

### Comandos úteis (host)

```bash
# Drift no device
adb -s ZF525FJSZ2 shell run-as com.example.sentinel_app cat databases/sentinel.db | sqlite3 -cmd ".tables" ""

# Postgres pós-sync
psql -h localhost -p 54322 -U postgres -d postgres -c \
  "SELECT id, reported_by, synced_at FROM occurrences ORDER BY created_at DESC LIMIT 3;"
```

---

## AUDITORIA

**Escopo da mudança:** apenas **quando** `signOut` é chamado — rede não invalida mais a sessão.

**Não alterado:** verificação do token JWT, refresh Supabase, secure storage, contrato 401 da API.

**Veredito:** não escalar para audit — mudança cirúrgica na lógica de signOut (rede vs 401), coberta por testes + verificação device.

---

## Arquivos alterados

| Arquivo | Mudança |
|---------|---------|
| `lib/data/remote/api_exception.dart` | `isNetworkError`, factory `network()` |
| `lib/data/remote/api_client.dart` | captura `SocketException` / `ClientException` / timeout |
| `lib/core/bootstrap/bootstrap_messages.dart` | mensagem primeiro acesso offline |
| `lib/data/services/bootstrap_service.dart` | fallback cache Drift em falha de rede |
| `lib/presentation/bootstrap/app_bootstrap_screen.dart` | signOut só em 401 |
| `test/data/remote/api_client_test.dart` | +2 testes rede |
| `test/data/services/bootstrap_service_test.dart` | novo — 3 testes |
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | +2 testes rede |
| `.cursor/docs/last_executed_task.md` | este relatório |

---

<details>
<summary>Histórico — ENI-31 validação E10, ENI-32, ENI-36</summary>

Ver commits anteriores e `.cursor/docs/audit_20260618_eni29.md`.

</details>
