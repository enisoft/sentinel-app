# Última tarefa executada — ENI-31 Validação ponta a ponta E10 (device)

Pedido: roteiro de verificação + registro de evidência do ciclo completo E10.0→E10.2 no device (G56). **Sem feature nova.** Provar: login → catálogo → captura (fake JPEG real) → upload TUS → sync JSON → Postgres.

Data: 2026-06-18  
Device: **moto g56 5G** (`ZF525FJSZ2`) — `flutter run` ativo  
Operador: `operador@test.com` / uid `b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11`  
`.env` app: `SUPABASE_URL=http://192.168.15.7:54321`, `API_BASE_URL=http://192.168.15.7:8000/api/v1`

---

## Pré-requisitos

| Item | Status |
|------|--------|
| Backend Laravel `:8000` | ✅ `TcpTestSucceeded` |
| Supabase Auth/Storage `:54321` | ✅ `TcpTestSucceeded` |
| Postgres `:54322` | ✅ `TcpTestSucceeded` |
| Operador provisionado | ✅ `public.users` — 1 linha |
| App no G56 com IP LAN | ✅ terminal `flutter run -d ZF525FJSZ2` |

---

## Checklist ENI-31

| # | Passo | Resultado |
|---|-------|-----------|
| 1 | Login → bootstrap (sem loop/401) | ✅ |
| 2 | Catálogo carregado (dropdowns preenchidos) | ✅ |
| 3 | Captura + form + confirmar → fila | ✅ |
| 4 | Sync → Postgres (`reported_by`, `synced_at`, path canônico) | ✅ |
| 5 | Storage `sentinel-media` (`owner_id` = operador) | ✅ |
| 6 | Resiliência offline (captura sem rede → fila → sync ao religar) | ❌ **Não executado nesta sessão** |

**Veredito E10 (E10.0→E10.2):** ciclo online **validado ponta a ponta**. Passo 6 permanece pendente de execução manual deliberada.

---

## Passo 1 — Login / bootstrap

**Device:** teclado IME aberto/fechado no terminal `flutter run` (form de login); app seguiu para tela de captura (rotação landscape após interação, sem crash).

**Drift (`sentinel.db` no device):**

```
PROFILE ('b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11', 'Operador', 'agente', None)
```

**API (host, mesma credencial do operador):**

```
LOGIN_OK sub=b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11
ME_OK id=b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11 name=Operador
```

Sem loop de bootstrap nem 401 observados; perfil cacheado localmente.

---

## Passo 2 — Catálogo

**API (JWT operador):**

```
categories items=3 deleted=0
observables items=2 deleted=0
municipalities items=3 deleted=0
```

**Drift no device:**

```
categories COUNT = 3
observables COUNT = 2
```

Dropdowns de categoria e observável têm dados suficientes para preenchimento no form.

---

## Passo 3 — Captura → form → fila

Ocorrência de validação desta sessão (mais recente no device e no Postgres):

| Campo | Valor |
|-------|-------|
| `occurrence_id` | `387d8d8d-3ff9-46e1-86b4-f1a3d07a63d1` |
| `media_id` | `099e4bdd-a318-4298-99de-8ef281fb449e` |
| JPEG local | `/data/user/0/.../cache/fake_capture_1.jpg` (FakeDeviceCameraSource) |
| Estado fila (device) | `sync_state = synced`, `failed_phase = NULL`, `retry_count = 0` |

**Observação:** 4 ocorrências antigas permanecem `failed` / `media_uploading` (paths `/fake/captures/photo.jpg` pré-ENI-36) — fora do escopo desta validação; não bloqueiam o ciclo E10 atual.

---

## Passo 4 — Postgres (Laravel)

**Query:**

```sql
SELECT o.id, o.reported_by, o.synced_at,
       om.id AS media_id, om.path
FROM occurrences o
LEFT JOIN occurrence_media om ON om.occurrence_id = o.id
WHERE o.reported_by = 'b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11'
ORDER BY o.created_at DESC
LIMIT 3;
```

**Saída:**

```
                  id                  |             reported_by              |      synced_at      |               media_id               |                                           path
--------------------------------------+--------------------------------------+---------------------+--------------------------------------+-------------------------------------------------------------------------------------------
 387d8d8d-3ff9-46e1-86b4-f1a3d07a63d1 | b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11 | 2026-06-18 04:55:27 | 099e4bdd-a318-4298-99de-8ef281fb449e | occurrences/387d8d8d-3ff9-46e1-86b4-f1a3d07a63d1/099e4bdd-a318-4298-99de-8ef281fb449e.jpg
 603cf726-4307-457b-9586-37cddf863786 | b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11 | 2026-06-18 04:09:24 |                                      |
 f9850290-a921-4b35-98cc-31b786a66170 | b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11 | 2026-06-18 04:09:37 | 37601930-bdb8-467e-946f-2a8d0e1d0809 | occurrences/f9850290-a921-4b35-98cc-31b786a66170/37601930-bdb8-467e-946f-2a8d0e1d0809.jpg
```

✅ `reported_by` = uid do operador; ✅ `synced_at` preenchido; ✅ path canônico `occurrences/{id}/{media_id}.jpg`.

Delay captura→sync desta ocorrência: **25 s** (TUS + JSON).

---

## Passo 5 — Storage (Supabase)

**Query `storage.objects`:**

```sql
SELECT id, name, owner_id, bucket_id, created_at
FROM storage.objects
WHERE bucket_id = 'sentinel-media'
ORDER BY created_at DESC
LIMIT 3;
```

**Saída:**

```
                  id                  |                                           name                                            |               owner_id               |   bucket_id    |          created_at
--------------------------------------+-------------------------------------------------------------------------------------------+--------------------------------------+----------------+-------------------------------
 ff0aba1a-e93a-433e-8ff7-01554b604c99 | occurrences/387d8d8d-3ff9-46e1-86b4-f1a3d07a63d1/099e4bdd-a318-4298-99de-8ef281fb449e.jpg | b0e07b5a-5ecc-4ec8-8af8-dd68b97fdb11 | sentinel-media | 2026-06-18 04:55:26.917745+00
 6e68770d-26e3-44df-a613-997703fd5456 | occurrences/550e8400-e29b-41d4-a716-446655440000/a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg | 5df972f1-0d09-4b65-a694-49c638aedc24 | sentinel-media | 2026-06-16 18:12:36.302354+00
 46dd2cd0-eecc-430e-a069-03bc035f291f | occurrences/550e8400-e29b-41d4-a716-446655440000/8f14e45f-ceea-467f-a0f8-5c3b2e1a9d00.jpg | 5df972f1-0d09-4b65-a694-49c638aedc24 | sentinel-media | 2026-06-16 18:04:40.661682+00
```

✅ Objeto no bucket `sentinel-media`; ✅ `owner_id` = uid do operador (RLS E6).

---

## Passo 6 — Resiliência offline

**Status:** ❌ **Não executado** — nesta sessão ENI-31 não foi feita captura deliberada com rede desligada (modo avião/Wi‑Fi off) seguida de religamento e observação da fila.

**Nota indireta (não substitui o roteiro):** ocorrências seed com `created_at = 2026-06-15` sincronizaram em `2026-06-18` (delay ~64 h), sugerindo fila offline retroativa — mas sem captura offline **nesta** passagem documentada.

**Para fechar ENI-31 por completo:** repetir passos 3→4 com modo avião ativo na captura, confirmar item `local_saved`/`failed` na fila, religar rede e colar evidência Postgres + drift.

---

## Atualização ENI-14 / épico E10

| Sub-épico | Escopo | Status pós ENI-31 |
|-----------|--------|-------------------|
| **E10.0** | Login Supabase, bootstrap `/me`, catálogo delta offline | ✅ Validado no device |
| **E10.1** | Sync JSON ocorrências (`POST /occurrences/sync`) | ✅ Validado — `synced_at` + `reported_by` corretos |
| **E10.2** | Upload TUS resumable → Storage → path canônico → JSON | ✅ Validado — JPEG fake real, objeto em `sentinel-media`, path em `occurrence_media` |
| **E10.3+** | Check-in sync HTTP, FGS, Wi‑Fi policy | Fora deste roteiro |

Testes automatizados permanecem verdes: **`flutter test` → 60 passed** (ENI-32).

---

## Arquivos tocados

| Arquivo | Ação |
|---------|------|
| `.cursor/docs/last_executed_task.md` | este relatório ENI-31 |

Nenhum código de produção alterado (validação manual, conforme escopo).

---

<details>
<summary>Histórico — ENI-32, ENI-36, ENI-29, ENI-28</summary>

Ver `.cursor/docs/audit_20260618_eni29.md` e commits anteriores.

</details>
