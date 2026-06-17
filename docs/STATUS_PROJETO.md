# Status do Projeto — Sentinel Backend

Última atualização: 2026-06-17

## Visão geral

| Área | Status |
|------|--------|
| Schema de domínio (migrations) | Pronto |
| API app-facing (`/me`, catálogo, occurrences, check-ins) | Pronto |
| Sync offline de ocorrências | Pronto |
| Sync offline de check-ins | Pronto |
| Testes da API app-facing | Pronto (`tests/Feature/Api/V1/`) |
| Models Eloquent | Parcial (`Occurrence`, `OccurrenceMedia`, `Observable`, `Category`, `CheckIn`, `Task`, `Municipality`, `User`, `Role`) |
| API painel / tasks / push | Pendente |
| Autenticação Supabase Auth (JWT HS256) | Pronto (middleware `auth.supabase`) |
| Provisionamento de operadores | Pronto (`sentinel:create-operator` + Admin API GoTrue) |
| Seeders (catálogo + roles) | Pronto (`DatabaseSeeder` idempotente: roles, municípios, categorias, observables) |
| Storage privado + RLS (Supabase) | Pronto (`20260615120000_*` + `20260616120000_sentinel_media_select_owner_only.sql`) |
| Push notifications | Fase avançada |

**Models Eloquent — pendências:** faltam models para `groups`, `task_targets` e `task_assignments` (necessários em fases futuras do painel e de tasks).

**Testes do sync — cenários cobertos:**

0. `test_suite_runs_against_testing_schema` — suíte executa no schema `testing`, sem tocar o `public`.
1. `test_sync_accepts_batch_of_occurrences_with_client_uuids` — batch com UUIDs gerados no cliente, mídia anexa e contadores de resposta.
2. `test_resync_accumulates_media_without_deleting_existing` — re-sync acumulativo de mídia (mídias ausentes no payload não são removidas).
3. `test_client_timestamps_persist_when_sent_in_payload` — `created_at`/`updated_at` do App persistem com o valor enviado.
4. `test_synced_at_is_set_by_server_on_create_and_resync_and_client_value_is_ignored` — `synced_at` preenchido pelo servidor no create e atualizado no re-sync; valor enviado pelo cliente é ignorado.
5. `test_sync_with_valid_token_sets_reported_by_from_sub` — JWT válido; `reported_by` gravado a partir do claim `sub`.
6. `test_sync_without_authorization_returns_401` — sem header `Authorization`.
7. `test_sync_with_invalid_signature_returns_401` — assinatura HS256 inválida.
8. `test_sync_with_expired_token_returns_401` — token com `exp` no passado.
9. `test_sync_with_unknown_sub_returns_401` — `sub` sem linha correspondente em `public.users`.
10. `test_sync_ignores_reported_by_in_body` — `reported_by` enviado no body é ignorado; vence o id do token.

**Testes de provisionamento — cenários cobertos** (`tests/Feature/OperatorProvisioningTest.php`):

1. `test_create_operator_persists_profile_with_auth_uid_and_foreign_keys` — uid do mock GoTrue vira `public.users.id`; `role_id` e `municipality_id` corretos.
2. `test_create_operator_is_idempotent_by_email` — e-mail já existente não dispara nova chamada ao GoTrue.
3. `test_partial_failure_triggers_compensation_delete_auth_user` — falha ao criar perfil dispara `deleteAuthUser`.
4. `test_partial_failure_with_failed_compensation_reports_orphan` — compensação falha → exceção com uid órfão em `auth.users`.
5. `test_database_seeder_is_idempotent` — roles (`admin`, `coordenador`, `agente`), municípios, categorias e observables via `firstOrCreate`.

**Testes de `/me` — cenários cobertos** (`tests/Feature/Api/V1/MeTest.php`):

1. `test_me_with_valid_token_returns_operator_profile` — retorna `id`, `name`, `role` (slug), `municipality_id`, `photo_path`; sem `email`/`password`.
2. `test_me_without_token_returns_401` — sem header `Authorization`.

**Testes de catálogo — cenários cobertos** (`tests/Feature/Api/V1/CatalogSyncTest.php`):

1. `test_observables_without_updated_since_returns_all_items_and_empty_deleted_ids` — snapshot completo de observables.
2. `test_categories_without_updated_since_returns_all_items_and_empty_deleted_ids` — snapshot completo de categorias.
3. `test_municipalities_without_updated_since_returns_all_items_and_empty_deleted_ids` — snapshot completo de municípios.
4. `test_updated_since_filters_only_items_changed_after_date` — delta por `updated_at`.
5. `test_soft_deleted_category_appears_in_deleted_ids_when_updated_since_is_before_deletion` — soft-delete em `deleted_ids`.
6. `test_server_time_is_present_and_in_utc` — `server_time` em ISO 8601 UTC.
7. `test_observables_response_includes_only_public_fields` — somente `id`, `type`, `name` (sem `document`, etc.).
8. `test_catalog_*_without_token_returns_401` — observables, categories e municipalities exigem JWT.

**Testes de check-ins — cenários cobertos** (`tests/Feature/Api/V1/CheckInSyncTest.php`):

1. `test_sync_accepts_batch_of_check_ins_with_client_uuids` — batch com UUIDs do cliente e contadores de resposta.
2. `test_resync_updates_existing_check_in_by_id` — upsert por `id`.
3. `test_sync_ignores_user_id_in_body` — `user_id` derivado do token.
4. `test_captured_at_persists_from_client_payload` — `captured_at` do App persiste.
5. `test_synced_at_is_set_by_server_and_client_value_is_ignored` — `synced_at` autoridade do servidor.
6. `test_sync_without_authorization_returns_401` — sem token.
7. `test_sync_returns_ids_in_payload_order` — `data.ids` na ordem do payload.

---

## Modelo de dados

### Tabelas principais

| Tabela | Propósito |
|--------|-----------|
| `roles` | Papéis de sistema (RBAC) |
| `municipalities` | Municípios (geo, filtros, targets de tasks) |
| `categories` | Categorias administráveis de ocorrências (opcional no report) |
| `observables` | Pessoas/organizações monitoráveis (catálogo admin) |
| `users` | Agentes e coordenadores (`photo_path`, `municipality_id`) |
| `groups` | Equipes operacionais |
| `group_user` | Membros de equipes |
| `occurrences` | Reports de campo (sync offline, UUID do App) |
| `occurrence_media` | Mídias anexadas (image/audio/video, caminho no Storage) |
| `check_ins` | Presença do operador (check-in manual, sync offline, UUID do App) |
| `tasks` | Missões criadas no painel (sem mídia) |
| `task_targets` | Alvos da missão (user, group, municipality) |
| `task_assignments` | Inbox por usuário (aceitar/rejeitar/concluir) |

### Infraestrutura Laravel

Tabelas auxiliares criadas pelas migrations padrão do framework (não fazem parte do domínio de negócio):

| Tabela | Propósito |
|--------|-----------|
| `cache` | Cache em banco (`CACHE_STORE=database`) |
| `jobs` | Fila de jobs (`QUEUE_CONNECTION=database`) |
| `sessions` | Sessões web |
| `password_reset_tokens` | Tokens de redefinição de senha |

### Conceitos importantes

- **`reported_by`** — quem registrou a ocorrência; derivado do claim `sub` do JWT Supabase no sync (não é campo de entrada do payload).
- **`assigned_to`** — responsável/revisor; preenchido **somente no painel web**, não no sync.
- **`observable_id`** — alvo monitorável opcional (político, org…); catálogo admin.
- **`occurrence_id` em tasks** — vínculo opcional entre missão e ocorrência origem.
- **`created_at` / `updated_at` (ocorrência)** — timestamps offline do App; quando enviados no payload, persistem com o valor do cliente. Quando ausentes, o Laravel define automaticamente.
- **`synced_at` (ocorrência)** — autoridade do **servidor**; preenchido com `now()` a cada sync (create e update). Valores enviados pelo App são **ignorados** (campo não faz parte do contrato de request).
- **Upload de mídia** — App envia arquivo direto ao **Supabase Storage** (bucket privado `sentinel-media`); o sync persiste o **caminho relativo** do objeto em `occurrence_media.path`. O backend aceita a string sem validar visibilidade ou formato de URL.
- **Convenção de path no Storage** — `occurrences/{occurrence_id}/{media_id}.{ext}` (ex.: `occurrences/550e8400-e29b-41d4-a716-446655440000/8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00.jpg`). O `occurrence_id` e o `media_id` são UUIDs gerados no App; `{ext}` é a extensão do arquivo. RLS valida esse formato no **upload** (INSERT); **leitura autenticada** (SELECT) exige `owner_id = auth.uid()` — operador só re-baixa o que ele mesmo subiu; o painel lê tudo via `service_role` (bypass RLS, nunca exposto ao App).
- **`occurrence_media`** — não há `created_at`/`updated_at` offline no contrato de sync da mídia; timestamps da tabela seguem o padrão Laravel. `synced_at` não foi adicionado em `occurrence_media` (sem necessidade de rastrear sync por item de mídia nesta fase).
- **Re-sync de mídias** — acumulativo (upsert por `id`); mídias antigas **não são removidas** se ausentes no payload.
- **`user_id` (check-in)** — derivado do claim `sub` do JWT no sync de check-ins (não é campo de entrada do payload).
- **`synced_at` (check-in)** — autoridade do **servidor**; preenchido com `now()` a cada sync; valor enviado pelo App é **ignorado**.

---

## Provisionamento de operadores

Operadores **não** se cadastram (sem self-signup). Admin provisiona credencial + perfil via Artisan.

### Modelo de identidade

| Camada | Tabela | Conteúdo |
|--------|--------|----------|
| Credencial | `auth.users` (Supabase Auth) | e-mail, senha, MFA, tokens |
| Perfil | `public.users` (Laravel) | `role_id`, `municipality_id`, `name`, `photo_path`, `is_active` |

**`public.users.id` = `auth.users.id`** (mesmo UUID). O middleware `auth.supabase` resolve o operador pelo claim `sub` do JWT.

### Comando

```bash
php artisan db:seed   # roles, municípios, categorias e observables (idempotente; não chama GoTrue)

php artisan sentinel:create-operator agent@example.com 'SenhaSegura123' \
  --role=agente \
  --municipality=<uuid-do-municipio> \
  --name="Nome do Agente"
```

| Opção | Default | Descrição |
|-------|---------|-----------|
| `--role` | `agente` | Slug do papel: `admin`, `coordenador`, `agente` |
| `--municipality` | — | UUID do município (opcional) |
| `--name` | parte local do e-mail | Nome de exibição |

**Fluxo:**

1. `GoTrueAdminService` → `POST {SUPABASE_URL}/auth/v1/admin/users` (Admin API) → retorna `uid`.
2. Insert em `public.users` com o **mesmo** `uid`, `role_id`, `municipality_id`, `is_active=true`.
3. Se o passo 2 falhar após o 1, tenta `deleteAuthUser(uid)` (compensação). Se a compensação também falhar, reporta usuário órfão em `auth.users`.
4. Idempotência: e-mail já existente em `public.users` → aviso, sem duplicar.

### Dependência: `SUPABASE_SERVICE_ROLE_KEY`

Chave **poderosa** (ignora RLS). Uso **somente server-side** no comando/serviço Admin — **nunca** expor ao app mobile ou frontend.

Obter no Supabase local:

```bash
npx supabase status -o env
# copiar SERVICE_ROLE_KEY → SUPABASE_SERVICE_ROLE_KEY no .env
```

Configurada em `config/services.php` → `services.supabase.service_role_key`.

---

## Endpoints prontos

### `POST /api/v1/occurrences/sync`

Sincroniza ocorrências criadas offline no **sentinel-app**. UUIDs gerados no cliente; upsert por `id`.

**Autenticação:** Supabase Auth — header `Authorization: Bearer <JWT>` (HS256). O middleware `auth.supabase` valida assinatura, `exp`, `aud == authenticated` e resolve `public.users` pelo claim `sub`. Identidade sem perfil em `public.users` retorna 401.

#### Request

| Item | Valor |
|------|-------|
| Método | `POST` |
| URL | `/api/v1/occurrences/sync` |
| Headers | `Content-Type: application/json`, `Accept: application/json`, `Authorization: Bearer <JWT Supabase>` |

**Body (JSON):**

```json
{
  "occurrences": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "observable_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "category_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "title": "Vazamento no corredor",
      "description": "Água acumulada próximo ao elevador.",
      "status": "pending",
      "priority": "high",
      "location": "Bloco A - 2º andar",
      "latitude": -25.5284,
      "longitude": -49.1758,
      "occurred_at": "2026-06-10T14:30:00Z",
      "resolved_at": null,
      "created_at": "2026-06-10T14:35:00Z",
      "updated_at": "2026-06-10T14:35:00Z",
      "media": [
        {
          "id": "8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00",
          "media_type": "image",
          "path": "occurrences/550e8400-e29b-41d4-a716-446655440000/8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00.jpg",
          "mime_type": "image/jpeg",
          "original_name": "foto_corredor.jpg",
          "size_bytes": 245760,
          "sort_order": 0
        },
        {
          "id": "9a25f560-dffb-5780-b1a9-6d4c3f2b0e11",
          "media_type": "audio",
          "path": "occurrences/550e8400-e29b-41d4-a716-446655440000/9a25f560-dffb-5780-b1a9-6d4c3f2b0e11.m4a",
          "mime_type": "audio/mp4",
          "original_name": "nota_voz.m4a",
          "size_bytes": 512000,
          "duration_seconds": 32,
          "sort_order": 1
        }
      ]
    }
  ]
}
```

#### Campos da ocorrência

| Campo | Tipo | Obrigatório | Origem | Observação |
|-------|------|-------------|--------|------------|
| `id` | UUID | Sim | App | PK; gerado no cliente |
| `reported_by` | — | **Não enviar** | Servidor | Derivado do claim `sub` do JWT; ignorado se enviado no body |
| `observable_id` | UUID | Não | App | Deve existir no catálogo admin |
| `category_id` | UUID | Não | App | Deve existir no catálogo admin |
| `title` | string | Sim | App | Máx. 255 caracteres |
| `description` | string | Sim | App | Texto livre |
| `status` | string | Sim | App | Máx. 50 caracteres |
| `priority` | string | Sim | App | Máx. 50 caracteres |
| `location` | string | Não | App | Endereço legível; máx. 255 caracteres |
| `latitude` | decimal | Não | App | Enviar com `longitude` (Google Maps) |
| `longitude` | decimal | Não | App | Enviar com `latitude` |
| `occurred_at` | datetime | Sim | App | ISO 8601 |
| `resolved_at` | datetime | Não | App | `null` se aberta |
| `created_at` / `updated_at` | datetime | Não | App | Timestamps offline; quando enviados, persistem com valor do cliente |
| `synced_at` | — | **Não enviar** | Servidor | Preenchido pelo backend a cada sync; ignorado se enviado |
| `assigned_to` | — | **Não enviar** | Painel web | Atribuição posterior no backend web |

#### Campos de cada mídia (`media[]`)

| Campo | Tipo | Obrigatório | Observação |
|-------|------|-------------|------------|
| `id` | UUID | Sim | Gerado no App |
| `media_type` | string | Sim | `image`, `audio` ou `video` |
| `path` | string | Sim | Caminho relativo no bucket `sentinel-media`: `occurrences/{occurrence_id}/{media_id}.{ext}` |
| `mime_type` | string | Sim | Deve começar com `{media_type}/` |
| `original_name` | string | Não | Nome do arquivo no dispositivo |
| `size_bytes` | integer | Não | Tamanho em bytes |
| `sort_order` | integer | Não | Ordem de exibição (default 0) |
| `duration_seconds` | integer | Não | Recomendado para áudio/vídeo |

#### Response `200 OK`

```json
{
  "message": "Ocorrências sincronizadas com sucesso.",
  "data": {
    "synced_count": 1,
    "created_count": 1,
    "updated_count": 0,
    "ids": [
      "550e8400-e29b-41d4-a716-446655440000"
    ]
  }
}
```

| Campo | Descrição |
|-------|-----------|
| `synced_count` | Total de ocorrências processadas |
| `created_count` | Registros novos |
| `updated_count` | Registros atualizados (mesmo `id`) |
| `ids` | UUIDs sincronizados (`synced_ids`), na ordem do payload |

**Persistência no servidor (não retornada no JSON de resposta):** cada ocorrência sincronizada recebe `reported_by = sub do JWT` e `synced_at = now()` no banco. O App confirma sucesso pela presença do `id` em `data.ids`.

#### Response `401 Unauthorized`

Sem token:

```json
{
  "message": "Token de autenticação ausente."
}
```

Token inválido, expirado ou usuário sem perfil:

```json
{
  "message": "Token de autenticação inválido."
}
```

```json
{
  "message": "Usuário não autorizado."
}
```

#### Response `422 Unprocessable Entity`

Erros de validação do payload (campos obrigatórios, UUIDs inválidos, FKs inexistentes, etc.).

#### Exemplo cURL

```bash
curl -X POST http://localhost:8000/api/v1/occurrences/sync \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <JWT_SUPABASE>" \
  -d @payload.json
```

---

### `GET /api/v1/me`

Retorna o perfil do operador autenticado. O app chama no startup.

**Autenticação:** mesmo contrato JWT do grupo `/api/v1`.

#### Request

| Item | Valor |
|------|-------|
| Método | `GET` |
| URL | `/api/v1/me` |
| Headers | `Accept: application/json`, `Authorization: Bearer <JWT Supabase>` |

Sem query params nem body.

#### Response `200 OK`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Operador Silva",
  "role": "agente",
  "municipality_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "photo_path": "avatars/operador.jpg"
}
```

| Campo | Tipo | Observação |
|-------|------|------------|
| `id` | UUID | Mesmo `sub` do JWT / `public.users.id` |
| `name` | string | Nome de exibição |
| `role` | string | Slug do papel (`admin`, `coordenador`, `agente`) |
| `municipality_id` | UUID | Nullable |
| `photo_path` | string | Nullable; caminho relativo no storage (upload de avatar é fase futura) |

**Não retorna:** `email`, `password`, `role_id`, `is_active`.

#### Response `401 Unauthorized`

Mesmas mensagens do sync (`Token de autenticação ausente.` / `Token de autenticação inválido.` / `Usuário não autorizado.`).

#### Exemplo cURL

```bash
curl -X GET http://localhost:8000/api/v1/me \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <JWT_SUPABASE>"
```

---

### `GET /api/v1/catalog/{observables|categories|municipalities}`

Download de catálogo para uso offline no app. Padrão **delta sync** por `updated_since`.

**Autenticação:** mesmo contrato JWT do grupo `/api/v1`.

#### Request

| Item | Valor |
|------|-------|
| Método | `GET` |
| URL | `/api/v1/catalog/observables` · `/api/v1/catalog/categories` · `/api/v1/catalog/municipalities` |
| Headers | `Accept: application/json`, `Authorization: Bearer <JWT Supabase>` |
| Query | `updated_since` (opcional) — ISO 8601; retorna itens com `updated_at` posterior e soft-deletes em `deleted_ids` |

#### Response `200 OK`

```json
{
  "updated_since": "2026-06-05T00:00:00Z",
  "server_time": "2026-06-12T10:00:00Z",
  "items": [
    { "id": "...", "type": "person", "name": "Político Exemplo" }
  ],
  "deleted_ids": []
}
```

| Campo | Descrição |
|-------|-----------|
| `updated_since` | Eco do query param; `null` se ausente (snapshot completo) |
| `server_time` | Timestamp UTC do servidor; o app usa como próximo `updated_since` |
| `items` | Registros criados/alterados desde `updated_since` (ou todos se ausente) |
| `deleted_ids` | UUIDs soft-deleted desde `updated_since`; vazio no snapshot completo |

**Campos por entidade em `items`:**

| Endpoint | Campos públicos |
|----------|-----------------|
| `observables` | `id`, `type`, `name` |
| `categories` | `id`, `name` |
| `municipalities` | `id`, `name`; `latitude`/`longitude` se preenchidos no banco |

Campos sensíveis ou administrativos (ex.: `document`, `slug`, `is_active`) **não** são expostos.

#### Response `401 Unauthorized`

Mesmas mensagens do sync.

#### Exemplo cURL

```bash
curl -X GET "http://localhost:8000/api/v1/catalog/observables?updated_since=2026-06-01T00:00:00Z" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <JWT_SUPABASE>"
```

---

### `POST /api/v1/check-ins/sync`

Sincroniza check-ins de presença criados offline no **sentinel-app**. UUIDs gerados no cliente; upsert por `id`.

**Autenticação:** mesmo contrato JWT do grupo `/api/v1`.

#### Request

| Item | Valor |
|------|-------|
| Método | `POST` |
| URL | `/api/v1/check-ins/sync` |
| Headers | `Content-Type: application/json`, `Accept: application/json`, `Authorization: Bearer <JWT Supabase>` |

**Body (JSON):**

```json
{
  "check_ins": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "latitude": -3.1190,
      "longitude": -60.0217,
      "accuracy": 8.5,
      "captured_at": "2026-06-12T09:00:00Z",
      "note": "Início do turno"
    }
  ]
}
```

#### Campos de cada check-in

| Campo | Tipo | Obrigatório | Origem | Observação |
|-------|------|-------------|--------|------------|
| `id` | UUID | Sim | App | PK; gerado no cliente |
| `user_id` | — | **Não enviar** | Servidor | Derivado do claim `sub` do JWT; ignorado se enviado |
| `latitude` | decimal | Sim | App | Entre -90 e 90; enviar com `longitude` |
| `longitude` | decimal | Sim | App | Entre -180 e 180 |
| `accuracy` | decimal | Não | App | Metros; ≥ 0 |
| `captured_at` | datetime | Sim | App | ISO 8601 |
| `note` | string | Não | App | Texto livre |
| `synced_at` | — | **Não enviar** | Servidor | Preenchido pelo backend a cada sync; ignorado se enviado |

#### Response `200 OK`

```json
{
  "message": "Check-ins sincronizados com sucesso.",
  "data": {
    "synced_count": 1,
    "created_count": 1,
    "updated_count": 0,
    "ids": [
      "550e8400-e29b-41d4-a716-446655440000"
    ]
  }
}
```

| Campo | Descrição |
|-------|-----------|
| `synced_count` | Total de check-ins processados |
| `created_count` | Registros novos |
| `updated_count` | Registros atualizados (mesmo `id`) |
| `ids` | UUIDs sincronizados, na ordem do payload |

#### Response `401 Unauthorized` / `422 Unprocessable Entity`

Mesmo padrão do sync de ocorrências.

#### Exemplo cURL

```bash
curl -X POST http://localhost:8000/api/v1/check-ins/sync \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <JWT_SUPABASE>" \
  -d @check_ins_payload.json
```

---

## Ambiente de testes

Ambiente local: **Postgres do Supabase CLI** em `127.0.0.1:54322`, database `postgres`, credenciais `postgres` / `postgres`.

| Variável | App (`.env`) | Testes (`phpunit.xml`) |
|----------|--------------|------------------------|
| `DB_CONNECTION` | `pgsql` | `pgsql` |
| `DB_HOST` | `127.0.0.1` | `127.0.0.1` |
| `DB_PORT` | `54322` | `54322` |
| `DB_DATABASE` | `postgres` | `postgres` |
| `DB_USERNAME` | `postgres` | `postgres` |
| `DB_PASSWORD` | `postgres` | `postgres` |
| `DB_SCHEMA` | `public` | `testing` |
| `SUPABASE_URL` | `http://127.0.0.1:54321` | `http://127.0.0.1:54321` |
| `SUPABASE_JWT_SECRET` | valor de `npx supabase status -o env` | segredo fixo em `phpunit.xml` |
| `SUPABASE_SERVICE_ROLE_KEY` | valor de `npx supabase status -o env` | não usada nos testes (GoTrue mockado) |

O `.env.example` foi corrigido para refletir o setup Supabase local (`DB_PORT=54322`, `postgres`/`postgres`, schema `public`) e inclui `SUPABASE_URL`, `SUPABASE_JWT_SECRET` e `SUPABASE_SERVICE_ROLE_KEY`. Os testes usam o schema `testing` no **mesmo** Postgres — isolados por `search_path` (`config/database.php` → `DB_SCHEMA`). Credenciais de teste de JWT estão versionadas em `phpunit.xml` (não dependem do `.env`).

O schema `testing` é criado automaticamente antes da suíte via [`tests/bootstrap.php`](tests/bootstrap.php) (`CREATE SCHEMA IF NOT EXISTS testing`). `RefreshDatabase` roda migrations apenas no schema `testing`; dados do `public` não são alterados.

```bash
php artisan test
```

**Recriar ambiente de teste do zero** (Supabase local rodando):

```bash
psql -h 127.0.0.1 -p 54322 -U postgres -d postgres \
  -c "DROP SCHEMA IF EXISTS testing CASCADE; CREATE SCHEMA testing;"

php artisan test
```

O bootstrap recria o schema vazio se ele não existir; o `DROP ... CASCADE` só é necessário para reset completo.

---

## Pendências (próximas fases)

- API painel web: triagem, kanban, atribuir `assigned_to` em ocorrências
- API CRUD admin: observables, categories, groups, municipalities, tasks
- Publicação de tasks → materializar `task_assignments`
- Inbox de tasks no app (`GET /tasks/assignments`, accept/reject/complete)
- Upload de avatar do operador (`photo_path` gravável via API)
- Push notifications (fase avançada)
