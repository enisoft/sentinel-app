# Sentinel — API que o app precisa (contrato + ordem de build)

Objetivo: definir a superfície de API mínima para o **sentinel-app** funcionar de
ponta a ponta, em ordem de prioridade. App e backend avançam em paralelo contra
este contrato.

Estado: atualizado em 2026-06-18 (pós-E10).

**Fonte de verdade dos contratos:** `routes/api.php` + `tests/Feature/Api/V1/` +
`SyncOccurrencesRequest` / `SyncCheckInsRequest` (validação 422 não testada em Feature).

Legenda: ✅ backend pronto e testado · 📱 consumido pelo sentinel-app · 🔜 a construir

---

## Onde estamos

- **Autenticação Supabase Auth (JWT dual)** — ✅ backend · 📱 app consome.
  `SUPABASE_JWT_ALGO` define HS256 (`SUPABASE_JWT_SECRET`) ou ES256 (JWKS).
  `alg` do token deve coincidir com o ambiente — sem fallback (algorithm confusion).
- **Provisionamento + seeds** — ✅ (`sentinel:create-operator`, `DatabaseSeeder`;
  testes em `OperatorProvisioningTest`).
- **`GET /me`** — ✅ · 📱
- **Catálogo delta** (`GET /catalog/*`) — ✅ · 📱
- **`POST /occurrences/sync`** — ✅ · 📱
- **`POST /check-ins/sync`** — ✅ backend · app **ainda não consome**
- **Storage privado + RLS** — ✅ (bucket `sentinel-media`; upload direto pelo app).
- Schema de domínio — ✅.
- **Inbox de tasks (P5)** — 🔜 (depende do painel publicar tasks).

---

## P0 — Decisões de fundação

### ✅ 📱 1. Auth: Laravel valida o JWT do Supabase (dual HS256/ES256)

App faz login no Supabase → JWT no header `Authorization: Bearer <jwt>` → middleware
`auth.supabase` valida via `SupabaseJwtVerifier` e resolve o usuário em `public.users`
pelo claim `sub`. `public.users.id` alinhado 1:1 com `auth.users.id` (UUID).

| Cenário | Status HTTP | Mensagem | Teste |
|---------|-------------|----------|-------|
| Sem `Authorization` | 401 | `Token de autenticação ausente.` | `MeTest`, `OccurrenceSyncTest`, `CatalogSyncTest`, `CheckInSyncTest` |
| Assinatura inválida | 401 | `Token de autenticação inválido.` | `OccurrenceSyncTest` |
| `exp` no passado | 401 | `Token de autenticação inválido.` | `OccurrenceSyncTest` |
| `aud` ≠ `authenticated` | 401 | `Token de autenticação inválido.` | `OccurrenceSyncTest` |
| Sem claim `exp` | 401 | `Token de autenticação inválido.` | `OccurrenceSyncTest` |
| `alg` divergente do env | 401 | `Token de autenticação inválido.` | `MeTest`, `SupabaseJwtVerifierTest` |
| `sub` sem perfil em `users` | 401 | `Usuário não autorizado.` | `OccurrenceSyncTest` |

**Operacional:** GoTrue local recente emite ES256 — `.env` deve ter `SUPABASE_JWT_ALGO=ES256`
(ver `.env.example`). PHPUnit usa `HS256` fixo em `phpunit.xml`.

### ✅ 📱 2. `reported_by` vem do token, nunca do payload

Derivado de `$request->user()->id`. Campo no body é ignorado.
`OccurrenceSyncTest::test_sync_ignores_reported_by_in_body`.

### ✅ 📱 3. Timestamps offline + `synced_at`

`created_at`/`updated_at` do cliente persistem; `synced_at` é setado pelo servidor
a cada sync e ignora valor do cliente. `OccurrenceSyncTest`, `CheckInSyncTest`.

### ✅ 4. Bucket privado + RLS (épico de Storage)

`path` guarda o caminho do objeto (não URL pública obrigatória). Bucket `sentinel-media`
privado; operador autenticado **sobe** (INSERT) e **lê apenas o que ele mesmo enviou**
(SELECT por `owner_id`); leitura ampla no painel via `service_role`. Convenção
recomendada: `occurrences/{occurrence_id}/{media_id}.{ext}`.

---

## Superfície de API por prioridade

> Convenção: prefixo `/api/v1/`, JSON, todas autenticadas (Bearer JWT).
> Detalhes expandidos (exemplos cURL, tabelas de campo): `STATUS_PROJETO.md`.

### ✅ 📱 P1 — Identidade

**`GET /me`** — perfil do operador autenticado. App chama no startup.

**Request:** sem body; sem query params.

**Response 200** (`MeTest::test_me_with_valid_token_returns_operator_profile`):

```json
{ "id": "<uuid>", "name": "<string>", "role": "agente",
  "municipality_id": "<uuid|null>", "photo_path": "<string|null>" }
```

| Campo | Obrigatório na resposta | Testado |
|-------|-------------------------|---------|
| `id` | Sim | Sim |
| `name` | Sim | Sim |
| `role` | Sim (slug) | Sim |
| `municipality_id` | Sim (pode ser null) | Sim |
| `photo_path` | Sim (pode ser null) | Sim |

**Ausentes na resposta (testado):** `email`, `password`, `is_active`, `role_id`.

**Erros 401 testados:** token ausente; `alg` trocado no header.

**Não testado em `/me`:** token expirado, assinatura inválida, `sub` desconhecido
(mesmo middleware das ocorrências — comportamento esperado idêntico).

---

### ✅ 📱 P2 — Catálogo offline (destrava a criação de ocorrência no app)

Delta sync por `updated_since` (query opcional, ISO 8601).

**`GET /catalog/observables?updated_since=<iso8601>`**
**`GET /catalog/categories?updated_since=<iso8601>`**
**`GET /catalog/municipalities?updated_since=<iso8601>`**

**Response 200** (estrutura comum — `CatalogSyncTest`):

```json
{
  "updated_since": "<iso8601|null>",
  "server_time": "<iso8601 UTC>",
  "items": [ ... ],
  "deleted_ids": [ "<uuid>", ... ]
}
```

| Comportamento | Testado |
|---------------|---------|
| Sem `updated_since`: todos os itens ativos, `deleted_ids: []` | Sim (3 endpoints) |
| Com `updated_since`: só `updated_at > since` | Sim (`observables`) |
| Soft-delete em `deleted_ids` | Sim (`categories`) |
| `server_time` UTC | Sim |
| 401 sem token | Sim (3 endpoints) |

**Campos em `items` (por endpoint):**

| Endpoint | Campos na resposta | Teste dedicado |
|----------|-------------------|----------------|
| `observables` | `id`, `type`, `name` | Sim — exclui `document`, `description` |
| `categories` | `id`, `name` | Implícito (snapshot); sem teste de campos excluídos |
| `municipalities` | `id`, `name`; `latitude`/`longitude` se preenchidos | Snapshot testado sem coords; inclusão condicional **não testada** |

- App guarda `server_time` e usa como próximo `updated_since`.
- Seeds: `php artisan db:seed`.

---

### ✅ 📱 P3 — Sync de ocorrências

`POST /occurrences/sync`

**Request body:**

| Campo raiz | Obrigatório | Testado |
|------------|-------------|---------|
| `occurrences` | Sim, array ≥ 1 | Sim |

| Campo por ocorrência | Obrigatório | Testado |
|----------------------|-------------|---------|
| `id` | Sim (UUID) | Sim |
| `title`, `description`, `status`, `priority` | Sim | Sim |
| `occurred_at` | Sim | Sim |
| `observable_id`, `category_id` | Não (FK se enviado) | Sim |
| `location`, `latitude`+`longitude`, `resolved_at` | Não | Sim (parcial) |
| `created_at`, `updated_at` | Não | Sim |
| `reported_by`, `synced_at` | Não enviar | Sim (ignorados) |
| `media[]` | Não | Sim |

| Campo por mídia | Obrigatório se `media` presente | Testado |
|-----------------|----------------------------------|---------|
| `id`, `media_type`, `path`, `mime_type` | Sim | Sim |
| `original_name`, `size_bytes`, `sort_order`, `duration_seconds` | Não | Sim (`duration_seconds`) |

**Response 200:**

```json
{
  "message": "Ocorrências sincronizadas com sucesso.",
  "data": { "synced_count": N, "created_count": N, "updated_count": N, "ids": ["..."] }
}
```

`data.ids` na ordem do payload (`OccurrenceSyncTest`).

**Erros 401:** ver tabela P0 (occurrences cobre todos os cenários listados).

**422:** regras em `SyncOccurrencesRequest` (incl. `mime_type` compatível com
`media_type`). **Não testado em Feature.**

**Divergência doc anterior corrigida:** `path` da mídia é string genérica (testes
usam URL completa); backend não valida formato de path.

---

### ✅ P4 — Check-ins (presença do operador)

**`POST /check-ins/sync`** — backend pronto; **app ainda não consome**.

**Request body:**

| Campo raiz | Obrigatório | Testado |
|------------|-------------|---------|
| `check_ins` | Sim, array ≥ 1 | Sim |

| Campo por check-in | Obrigatório | Testado |
|--------------------|-------------|---------|
| `id` | Sim (UUID) | Sim |
| `latitude`, `longitude` | Sim | Sim |
| `captured_at` | Sim | Sim |
| `accuracy`, `note` | Não | Sim |
| `user_id`, `synced_at` | Não enviar | Sim (`user_id` ignorado; `synced_at` servidor) |

**Response 200:**

```json
{
  "message": "Check-ins sincronizados com sucesso.",
  "data": { "synced_count": N, "created_count": N, "updated_count": N, "ids": ["..."] }
}
```

`data.ids` na ordem do payload (`test_sync_returns_ids_in_payload_order`).

**Erros 401 testados:** apenas token ausente. Demais cenários do middleware **não**
repetidos em `CheckInSyncTest`.

**422:** `SyncCheckInsRequest`. **Não testado em Feature.**

---

### 🔜 P5 — Inbox de tasks (fluxo top-down)

**`GET /tasks/assignments`** — missões atribuídas ao operador (task + targets + status).
**`POST /tasks/assignments/{id}/accept`**
**`POST /tasks/assignments/{id}/reject`**
**`POST /tasks/assignments/{id}/complete`**

> Depende de o painel criar/publicar tasks e materializar `task_assignments`.

---

## O que NÃO entra agora

A API do **painel web** (CRUD admin, triagem, kanban, atribuição de `assigned_to`)
**não bloqueia o app** — o app não consome essas rotas. Seeds de catálogo bastam
para desenvolvimento e teste do app de ponta a ponta.

---

## Upload de mídia (não passa pelo Laravel)

App → Supabase Storage direto via TUS, com o JWT do operador e políticas RLS no
bucket privado. O backend só recebe o `path` no sync. O time do app precisa de:
nome do bucket, política RLS, convenção de path. (Ver épico de Storage.)

---

## Ordem de execução sugerida (backend)

1. ✅ Auth dual + `reported_by` do token + timestamps/`synced_at`.
2. ✅ Provisionamento de usuários (`auth.users` + `public.users`) + seeds.
3. ✅ `GET /me`.
4. ✅ Catálogo (delta sync) + admin/seed mínimo.
5. ✅ Storage privado + RLS.
6. ✅ Check-ins.
7. 🔜 Inbox de tasks (depende do painel publicar tasks).

**Próximo foco (app):** consumir `POST /check-ins/sync` + consolidar upload TUS em produção.
