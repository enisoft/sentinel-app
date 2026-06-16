# Sentinel — API que o app precisa (contrato + ordem de build)

Objetivo: definir a superfície de API mínima para o **sentinel-app** funcionar de
ponta a ponta, em ordem de prioridade. App e backend avançam em paralelo contra
este contrato.

Estado: atualizado em 2026-06-14 (auth e timestamps já implementados — ver marcações).

---

## Onde estamos

- `POST /api/v1/occurrences/sync` — **pronto, testado e autenticado**. Upsert
  idempotente por UUID; `reported_by` vem do token; persiste `created_at`/
  `updated_at` do cliente; `synced_at` é autoridade do servidor; `data.ids` na
  ordem do payload.
- **Autenticação Supabase Auth (HS256)** — **pronta**. Grupo `/api/v1` protegido;
  middleware valida assinatura/`exp`/`aud`; identidade resolvida em `users` pelo `sub`.
- Schema de domínio — **pronto**.
- Catálogo, check-ins, inbox de tasks, `GET /me` — **a construir**.

Legenda de status: ✅ feito · 🔜 a construir

---

## P0 — Decisões de fundação

### ✅ 1. Auth: Laravel valida o JWT do Supabase (HS256)
App faz login no Supabase → JWT no header `Authorization: Bearer <jwt>` → middleware
valida e resolve o usuário em `public.users` pelo claim `sub`. `public.users.id`
alinhado 1:1 com `auth.users.id` (UUID). FEITO.

### ✅ 2. `reported_by` vem do token, nunca do payload
Derivado de `$request->user()->id`. Campo no body é ignorado. FEITO.

### ✅ 3. Timestamps offline + `synced_at`
`created_at`/`updated_at` do cliente persistem; `synced_at` é setado pelo servidor
a cada sync e ignora valor do cliente. FEITO.

### 🔜 4. Bucket privado + RLS (épico de Storage)
`path` guarda o caminho do objeto (não URL pública). Falta definir políticas RLS no
bucket do Supabase para o operador autenticado subir, e a convenção de path
(`occurrences/{occurrence_id}/{media_id}.{ext}`). A construir.

---

## Superfície de API por prioridade

> Convenção: prefixo `/api/v1/`, JSON, todas autenticadas (Bearer JWT).

### 🔜 P1 — Identidade

**`GET /me`** — perfil do operador autenticado. O app chama no startup.
```json
{ "id": "...", "name": "...", "role": "agente",
  "municipality_id": "...", "photo_path": "..." }
```

### 🔜 P2 — Catálogo offline (destrava a criação de ocorrência no app)

O app precisa baixar os catálogos para selecionar offline. Padrão de **delta sync**
por `updated_since`.

**`GET /catalog/observables?updated_since=<iso8601>`**
**`GET /catalog/categories?updated_since=<iso8601>`**
**`GET /catalog/municipalities?updated_since=<iso8601>`**

```json
{
  "updated_since": "2026-06-01T00:00:00Z",
  "server_time": "2026-06-12T10:00:00Z",
  "items": [ { "id": "...", "type": "person", "name": "..." } ],
  "deleted_ids": [ "..." ]
}
```
- `items`: criados/alterados desde `updated_since`.
- `deleted_ids`: removidos desde então (exige soft-delete) — o app apaga localmente.
- App guarda `server_time` e usa como próximo `updated_since`.

> Pré-requisito: provisionamento de usuários + admin/seed mínimo para popular o catálogo.

### ✅ P3 — Sync de ocorrências

`POST /occurrences/sync` — pronto e produtizado (auth, `reported_by` do token,
timestamps, `synced_at`). Resposta `data.ids` inalterada.

### 🔜 P4 — Check-ins (presença do operador)

**`POST /check-ins/sync`** — mesmo padrão offline-first/idempotente do occurrences.
```json
{ "check_ins": [
  { "id": "<uuid>", "latitude": -3.1, "longitude": -60.0,
    "accuracy": 8.5, "captured_at": "2026-06-12T09:00:00Z", "note": null }
] }
```
- `user_id` do token (não do payload).
- Resposta espelha o sync: `{ "data": { "synced_count", "ids" } }`.
- Nova tabela `check_ins` + migration.

### 🔜 P5 — Inbox de tasks (fluxo top-down)

**`GET /tasks/assignments`** — missões atribuídas ao operador (task + targets + status).
**`POST /tasks/assignments/{id}/accept`**
**`POST /tasks/assignments/{id}/reject`**
**`POST /tasks/assignments/{id}/complete`**

> Depende de o painel criar/publicar tasks e materializar `task_assignments`.

---

## O que NÃO entra agora

A API do **painel web** (CRUD admin, triagem, kanban, atribuição de `assigned_to`)
**não bloqueia o app** — o app não consome essas rotas. Exceção: um admin/seed
mínimo de catálogo é pré-requisito para testar o app de ponta a ponta.

---

## Upload de mídia (não passa pelo Laravel)

App → Supabase Storage direto via TUS, com o JWT do operador e políticas RLS no
bucket privado. O backend só recebe o `path` no sync. O time do app precisa de:
nome do bucket, política RLS, convenção de path. (Ver épico de Storage.)

---

## Ordem de execução sugerida (backend)

1. ✅ Auth + `reported_by` do token + timestamps/`synced_at`.
2. 🔜 Provisionamento de usuários (`auth.users` + `public.users`) + seeds.
3. 🔜 `GET /me`.
4. 🔜 Catálogo (delta sync) + admin/seed mínimo.
5. 🔜 Storage privado + RLS.
6. 🔜 Check-ins.
7. 🔜 Inbox de tasks (depende do painel publicar tasks).
