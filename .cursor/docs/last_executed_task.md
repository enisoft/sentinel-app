# Última tarefa executada — Serialização local → payload de sync

Pedido: camada de SERIALIZAÇÃO local → payload de sync, aderente ao contrato
(`docs/sentinel-api-app.md`, `sentinel-backend/STATUS_PROJETO.md`). Escopo fechado:
sem HTTP/TUS, sem câmera, sem rede real — tudo continua atrás da interface
`SyncGateway`. Fechar 2 divergências do audit: `created_at` de domínio em
`occurrences` e mapeamento `remotePath`→`path` na serialização; remover
`mediaUploadedAt` órfão de `check_ins`.

Data: 2026-06-14

## O que foi feito

### 1. Correções de schema (drift v2)

- **`occurrences`**: campo de domínio `createdAt` (`created_at` no SQLite),
  populado na criação do registro (distinto de `createdLocalAt` da fila).
- **`check_ins`**: removido `mediaUploadedAt` (check-in não tem pipeline de mídia).
- **Migration** v1→v2: recria tabelas (fundação pré-produção).

### 2. Serialização para o contrato

- **`SyncPayloadSerializer`** (`lib/data/sync/sync_payload_serializer.dart`):
  - `serializeOccurrencesSyncPayload` / `serializeOccurrence` — POST
    `/occurrences/sync`: nomes snake_case do contrato, `path` ← `remotePath`,
    `created_at`/`updated_at` de domínio, exclusão de `reported_by`, `assigned_to`,
    `synced_at` e campos da fila/local (`local_path`, `sync_state`, etc.).
  - `serializeCheckInsSyncPayload` / `serializeCheckIn` — POST `/check-ins/sync`
    (contrato P4): `id`, `latitude`, `longitude`, `accuracy`, `captured_at`, `note`;
    sem `user_id` nem campos de fila.
  - `toContractIso8601` — timestamps UTC sem fração de segundo (ex. `…T14:35:00Z`).

### 3. Repositório

- `OccurrenceRepository.createOccurrence` — aceita `createdAt` opcional; default = momento da criação.
- `OccurrenceRepository.getMedia` — lista mídias ordenadas por `sortOrder`.

### 4. Testes (sem rede)

- Ocorrência com 2 mídias → JSON bate com contrato P3 (nomes, `path`, `created_at`,
  ausência de campos server-only).
- Check-in → aderência ao contrato P4.
- 16 testes anteriores mantidos (+ 2 novos = **18**).

## Resultado dos testes

```
00:00 +0: loading C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart
00:00 +0: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: occurrence with media localSaved -> mediaUploading -> mediaDone -> jsonSyncing -> synced
00:00 +1: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: occurrence with media rejects mediaUploading when occurrence has no media
00:00 +2: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: occurrence without media localSaved -> mediaDone -> jsonSyncing -> synced
00:00 +3: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: check-in localSaved -> jsonSyncing -> synced
00:00 +4: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: check-in rejects media pipeline for check-in
00:00 +5: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: failure and retry canFail excludes synced and failed
00:00 +6: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: failure and retry stateForFailedPhase maps phase to active state
00:00 +7: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: failure and retry retry from failed restores failed phase state
00:00 +8: C:/New Projects/sentinel-project/sentinel-app/test/core/sync/sync_state_machine_test.dart: failure and retry invalid transition is rejected
00:00 +9: C:/New Projects/sentinel-project/sentinel-app/test/data/repositories/repositories_test.dart: OccurrenceRepository creates occurrence in localSaved with created_local_at
00:00 +10: C:/New Projects/sentinel-project/sentinel-app/test/data/repositories/repositories_test.dart: OccurrenceRepository transitions occurrence with media through pipeline
00:00 +11: C:/New Projects/sentinel-project/sentinel-app/test/data/repositories/repositories_test.dart: OccurrenceRepository occurrence without media skips upload states
00:00 +12: C:/New Projects/sentinel-project/sentinel-app/test/data/repositories/repositories_test.dart: OccurrenceRepository recordFailure increments retry and stores phase/reason
00:00 +13: C:/New Projects/sentinel-project/sentinel-app/test/data/repositories/repositories_test.dart: OccurrenceRepository retry restores jsonSyncing after json failure
00:00 +14: C:/New Projects/sentinel-project/sentinel-app/test/data/repositories/repositories_test.dart: CheckInRepository creates check-in and syncs without media pipeline
00:00 +15: C:/New Projects/sentinel-project/sentinel-app/test/data/repositories/repositories_test.dart: SyncQueueRepository getPending excludes synced and includes failed/intermediate
00:00 +16: C:/New Projects/sentinel-project/sentinel-app/test/data/sync/sync_payload_serializer_test.dart: SyncPayloadSerializer — occurrences serializes occurrence with 2 media matching sync contract
00:00 +17: C:/New Projects/sentinel-project/sentinel-app/test/data/sync/sync_payload_serializer_test.dart: SyncPayloadSerializer — check-ins serializes check-in matching P4 sync contract
00:00 +18: All tests passed!
```

Comando: `flutter test`

## Arquivos tocados

| Arquivo | Alteração |
|---------|-----------|
| `lib/data/local/tables/occurrences.dart` | `createdAt` de domínio |
| `lib/data/local/tables/check_ins.dart` | removido `mediaUploadedAt` |
| `lib/data/local/app_database.dart` | schema v2 + migration |
| `lib/data/local/app_database.g.dart` | regenerado (build_runner) |
| `lib/data/repositories/occurrence_repository.dart` | `createdAt` na criação; `getMedia` |
| `lib/data/sync/sync_payload_serializer.dart` | **novo** — serialização P3/P4 |
| `test/data/sync/sync_payload_serializer_test.dart` | **novo** — 2 testes de contrato |
| `test/data/repositories/repositories_test.dart` | assert `createdAt` na criação |
| `.cursor/docs/last_executed_task.md` | este relatório |

## Fora de escopo (mantido)

HTTP/TUS, `SyncGateway` implementação, câmera, rede real, envio do payload (E10).
