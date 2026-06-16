# Última tarefa executada — E9 fase 1: shell capture-first (sem câmera/GPS reais)

Pedido: interfaces abstratas (`CameraSource`, `LocationSource`, `HashService`) + fakes
em memória + UI shell capture-first. Câmera/GPS/hash reais ficam para fase 2 (device).
Escopo fechado: sem `camera`/`geolocator`/`permission_handler` no pubspec ou código.

Data: 2026-06-15

## O que foi feito

### 1. Interfaces (contrato, sem implementação real)

- **`CameraSource`** (`lib/domain/services/camera_source.dart`) — `capture()` → `CaptureResult` (caminho local + metadados).
- **`LocationSource`** (`lib/domain/services/location_source.dart`) — `getCurrentPosition()` → `GeoFix` (lat/lng/accuracy).
- **`HashService`** (`lib/domain/services/hash_service.dart`) — `hashFile()` → SHA-256 (contrato; fake determinístico nesta fase).
- Modelos: `CaptureResult`, `GeoFix` em `lib/domain/models/`.

### 2. Fakes em memória

- `FakeCameraSource`, `FakeLocationSource`, `FakeHashService` em `lib/data/fakes/`.
- Registrados no DI (`lib/app/di.dart`) para app e testes.

### 3. Orquestração capture-first

- **`CaptureOccurrenceService`** (`lib/data/services/capture_occurrence_service.dart`):
  - Disparo → captura + GPS + hash → rascunho em `local_saved` com mídia anexada.
  - Form atualiza rascunho (`updateDraftForm`).
  - Confirmar → `status: pending`, permanece em `local_saved` (fila da fundação).
- **`OccurrenceRepository.updateDraft`** — atualização parcial de campos do form.
- **`occurrence_media.content_hash`** — coluna nova (schema v3) para hash na captura.

### 4. UI shell (presentation/)

- **`CaptureHomeScreen`** — home = tela de captura (placeholder); botão dispara fake.
- **`OccurrenceDraftFormScreen`** — form pós-captura (categoria, observável, nota); nunca bloqueia o disparo.
- `main.dart` aponta para `CaptureHomeScreen`.

### 5. Testes (sem device)

- 3 unit (`capture_occurrence_service_test.dart`): rascunho com mídia + metadados; form + confirm enfileira; captura sem rede.
- 2 widget (`capture_flow_test.dart`): disparo → form; confirmar → fila.
- **18 testes anteriores mantidos** (+ 5 novos = **23**).

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
00:00 +16: C:/New Projects/sentinel-project/sentinel-app/test/data/services/capture_occurrence_service_test.dart: CaptureOccurrenceService fake capture creates local_saved draft with media and metadata
00:00 +17: C:/New Projects/sentinel-project/sentinel-app/test/data/services/capture_occurrence_service_test.dart: CaptureOccurrenceService form update and confirm enqueue occurrence in pending sync
00:00 +18: C:/New Projects/sentinel-project/sentinel-app/test/data/services/capture_occurrence_service_test.dart: CaptureOccurrenceService capture is not blocked by offline fakes (no network dependency)
00:00 +19: C:/New Projects/sentinel-project/sentinel-app/test/data/sync/sync_payload_serializer_test.dart: SyncPayloadSerializer — occurrences serializes occurrence with 2 media matching sync contract
00:00 +20: C:/New Projects/sentinel-project/sentinel-app/test/data/sync/sync_payload_serializer_test.dart: SyncPayloadSerializer — check-ins serializes check-in matching P4 sync contract
00:00 +21: C:/New Projects/sentinel-project/sentinel-app/test/presentation/capture/capture_flow_test.dart: capture button creates draft then shows form without blocking
00:01 +22: C:/New Projects/sentinel-project/sentinel-app/test/presentation/capture/capture_flow_test.dart: confirming form enqueues occurrence for sync
00:01 +23: All tests passed!
```

Comando: `flutter test`

## Arquivos tocados

| Arquivo | Alteração |
|---------|-----------|
| `lib/domain/models/capture_result.dart` | **novo** |
| `lib/domain/models/geo_fix.dart` | **novo** |
| `lib/domain/services/camera_source.dart` | **novo** — contrato abstrato |
| `lib/domain/services/location_source.dart` | **novo** — contrato abstrato |
| `lib/domain/services/hash_service.dart` | **novo** — contrato abstrato |
| `lib/data/fakes/fake_camera_source.dart` | **novo** |
| `lib/data/fakes/fake_location_source.dart` | **novo** |
| `lib/data/fakes/fake_hash_service.dart` | **novo** |
| `lib/data/services/capture_occurrence_service.dart` | **novo** — orquestração capture-first |
| `lib/data/local/tables/occurrence_media.dart` | `contentHash` |
| `lib/data/local/app_database.dart` | schema v3 + migration |
| `lib/data/local/app_database.g.dart` | regenerado |
| `lib/data/repositories/occurrence_repository.dart` | `updateDraft`, `contentHash` em `attachMedia` |
| `lib/presentation/capture/capture_home_screen.dart` | **novo** — home captura |
| `lib/presentation/capture/occurrence_draft_form_screen.dart` | **novo** — form pós-captura |
| `lib/app/di.dart` | registro de fakes + `CaptureOccurrenceService` |
| `lib/main.dart` | home → `CaptureHomeScreen` |
| `test/data/services/capture_occurrence_service_test.dart` | **novo** — 3 testes |
| `test/presentation/capture/capture_flow_test.dart` | **novo** — 2 testes widget |
| `.cursor/docs/last_executed_task.md` | este relatório |

## Fora de escopo (mantido)

Câmera/GPS reais (fase 2 device), `permission_handler`, HTTP/TUS, `SyncGateway` implementação, catálogo offline, worker de sync em background.
