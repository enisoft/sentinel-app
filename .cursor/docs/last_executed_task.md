# Última tarefa executada — ENI-41 / E10.3a: worker de sync sob demanda + estado observável

**Status: DONE** (Linear ENI-41 fechado em 2026-06-18)

Pedido: coordenador de sync chamável sob demanda sobre `OccurrenceSyncService.processPending`, estado observável (idle/syncing/lastResult/pendentes), guard de reentrância, botão na home, DI + testes. Sem FGS/nativo (ENI-42).

---

## Implementação

### 1. `OccurrenceSyncCoordinator` + estado

| Componente | Descrição |
|------------|-----------|
| `OccurrenceSyncCoordinatorState` | `status` (idle/syncing), `lastResult` (sucesso/erro + timestamp), `pendingCount` |
| `DefaultOccurrenceSyncCoordinator` | Orquestra `processPending()`; escuta `watchPending()` para contagem |
| Guard de reentrância | `_running` — chamada concorrente retorna `null` sem iniciar segundo ciclo |
| `FakeOccurrenceSyncCoordinator` | Fake controlável para testes (barreira, contador de chamadas) |

### 2. DI

- Produção: `DefaultOccurrenceSyncCoordinator` registrado como `OccurrenceSyncCoordinator` (lazy singleton).
- Testing: `configureDependenciesForTesting(..., occurrenceSyncCoordinator: fake)` aceita override.

### 3. Pontos de disparo migrados

| Local | Antes | Depois |
|-------|-------|--------|
| `AppBootstrapScreen` | `OccurrenceSyncService.processPending()` | `OccurrenceSyncCoordinator.syncNow()` |
| `OccurrenceDraftFormScreen` | fire-and-forget `processPending()` | fire-and-forget `syncNow()` |
| `CaptureHomeScreen` | — | botão **Sincronizar agora** + `ValueListenableBuilder` |

### 4. UI mínima (`CaptureHomeScreen`)

- Botão `sync_now_button`: dispara `syncNow()`, desabilitado enquanto sincroniza.
- Texto `N pendente(s)` quando `pendingCount > 0`.
- Mensagem de última falha em vermelho quando `lastResult.success == false`.

### 5. Correção pós-debug manual — rascunhos fora do sync

Decisão: só ocorrências **confirmadas** (`status = pending`) entram na fila; rascunhos ficam locais.

- `SyncQueueRepository.getPendingOccurrences()` filtra `status = pending`.
- Evita rascunhos abandonados irem ao sync, falharem com 422 (`validation:`) e ficarem presos no contador.

---

## Testes automatizados

**`flutter test` → 75 passed**

| Teste | Verifica |
|-------|----------|
| `occurrence_sync_coordinator_test` (5) | disparo, reentrância, falha, pendentes, fila vazia |
| `getPending excludes unconfirmed drafts` | rascunho não conta na fila |
| `processPending ignores unconfirmed drafts` | sync não toca `status = draft` |
| `draft capture is not in sync pending queue until confirmed` | captura sem confirmar → fila 0 |
| Demais suítes | bootstrap, capture flow, occurrence sync — verdes |

---

## Verificação manual — device G56

| # | Passo | Evidência | Status |
|---|-------|-----------|--------|
| 1 | Capturar OFFLINE → confirmar | Botão mostra pendente(s) | ✅ |
| 2 | Religar rede → **Sincronizar agora** | sincronizando → ocioso | ✅ |
| 3 | Postgres + Storage | ocorrência + objeto no bucket | ✅ |
| 4 | Botão com fila vazia | não quebra; ocioso | ✅ |
| 5 | Reinstalação limpa + fluxo completo | fila 0 após sync | ✅ |
| 6 | Rascunho sem confirmar | não incrementa pendentes (pós-fix) | ✅ |

**Nota debug:** itens presos na fila eram rascunhos `draft` com `validation:` — corrigido pelo filtro `status = pending`.

### Comandos úteis (host)

```powershell
# Copiar Drift do device (pacote + caminho corretos)
adb -s ZF525FJSZ2 exec-out run-as com.sentinel.sentinel_app cat app_flutter/sentinel.db > sentinel.db

sqlite3 sentinel.db "SELECT status, sync_state, COUNT(*) FROM occurrences GROUP BY status, sync_state;"

# Postgres pós-sync
psql -h localhost -p 54322 -U postgres -d postgres -c "SELECT id, reported_by, synced_at FROM occurrences ORDER BY created_at DESC LIMIT 3;"
```

---

## AUDITORIA

**Escopo:** orquestração Dart sobre fluxo já auditado (E10.1/10.2). Filtro de rascunhos é regra de fila local, sem mudança de contrato HTTP.

**Veredito:** não escalar para audit — report + testes verdes + verificação device OK.

---

## Arquivos alterados / criados

| Arquivo | Mudança |
|---------|---------|
| `lib/core/sync/occurrence_sync_coordinator_state.dart` | **novo** — modelos de estado |
| `lib/core/capture/occurrence_lifecycle_status.dart` | **novo** — `draft` / `pending` |
| `lib/data/services/occurrence_sync_coordinator.dart` | **novo** — interface + implementação |
| `lib/data/fakes/fake_occurrence_sync_coordinator.dart` | **novo** — fake controlável |
| `lib/data/fakes/fake_sync_gateway.dart` | `onBeforeSync` para testes de reentrância |
| `lib/data/repositories/sync_queue_repository.dart` | fila só `status = pending` |
| `lib/data/services/capture_occurrence_service.dart` | constantes de lifecycle |
| `lib/app/di.dart` | registro do coordinator |
| `lib/presentation/capture/capture_home_screen.dart` | botão sync + estado observável |
| `lib/presentation/bootstrap/app_bootstrap_screen.dart` | usa coordinator |
| `lib/presentation/capture/occurrence_draft_form_screen.dart` | usa coordinator |
| `test/data/services/occurrence_sync_coordinator_test.dart` | **novo** — 5 testes |
| `test/data/repositories/repositories_test.dart` | exclusão de drafts |
| `test/data/services/capture_occurrence_service_test.dart` | draft fora da fila |
| `test/data/services/occurrence_sync_service_test.dart` | `processPending` ignora draft |
| `test/presentation/capture/capture_flow_test.dart` | expectativa pré-confirm |
| `.cursor/docs/last_executed_task.md` | este relatório |
