# Última tarefa executada — ENI-42 / E10.3b: Foreground Service para sync em background

**Status: implementado** — verificação manual G56/G65 pendente

Pedido: sync com app minimizado / tela apagada via Foreground Service Android (`dataSync`), notificação persistente *"Sincronizando ocorrências…"*, worker ENI-41 em Dart. Sem UIDT (ENI-40), sem `connectivity_plus` (ENI-39).

Data: 2026-06-18

---

## Implementação

### Modelo

O sync **permanece 100% em Dart** (`OccurrenceSyncCoordinator` + `OccurrenceSyncService`). O FGS nativo só:

1. Eleva prioridade do processo (`startForeground`)
2. Exibe notificação ongoing
3. Inicia **antes** de `syncNow()` e para quando `getPending().totalCount == 0`

Disparo **somente** nos 3 pontos existentes (sem watcher automático na fila).

### Dart

| Componente | Função |
|------------|--------|
| `SyncForegroundPlatform` | MethodChannel `com.sentinel.sentinel_app/sync_foreground` |
| `OccurrenceSyncForegroundRunner` | `runIfPending()` — FGS + coordinator |
| `FakeSyncForegroundPlatform` | testes |

### Android (Kotlin)

| Arquivo | Função |
|---------|--------|
| `SyncForegroundService.kt` | FGS `dataSync`, notificação canal `sentinel_sync` |
| `MainActivity.kt` | MethodChannel start/stop + `POST_NOTIFICATIONS` |
| `AndroidManifest.xml` | permissões + declaração do service |
| `res/values/strings.xml` | textos da notificação |

### Pontos de disparo

- `AppBootstrapScreen` → `runner.runIfPending()`
- `OccurrenceDraftFormScreen` → `unawaited(runner.runIfPending())`
- `CaptureHomeScreen` → botão sync via `runner.runIfPending()`

### Limite MVP (aceito)

FGS `dataSync` tem teto **~6h/dia** no Android 15 — UIDT em ENI-40 pós-MVP.

---

## Testes automatizados

**`flutter test` → 78 passed** (+3 novos no foreground runner)

| Teste | Verifica |
|-------|----------|
| start antes de sync, stop quando fila vazia | FGS lifecycle |
| skip quando fila vazia | sem start desnecessário |
| não stop se ainda há pendentes | fila parcial |

Cobertura instrumentada Android: fora de escopo — verificação manual no device.

---

## Verificação manual — device G56/G65 (pendente)

| # | Passo | Evidência | Status |
|---|-------|-----------|--------|
| 1 | Logar online; capturar e **confirmar** | 1 pendente | ⬜ |
| 2 | Minimizar / apagar tela durante sync | Notificação *"Sincronizando ocorrências…"* | ⬜ |
| 3 | Aguardar conclusão | Notificação some; fila 0 | ⬜ |
| 4 | Postgres + Storage | `SELECT id, synced_at ...` + objeto no bucket | ⬜ |
| 5 | Android 13+: aceitar permissão de notificação | prompt na 1ª execução | ⬜ |

```powershell
adb -s <device> exec-out run-as com.sentinel.sentinel_app cat app_flutter/sentinel.db > sentinel.db
sqlite3 sentinel.db "SELECT sync_state, COUNT(*) FROM occurrences WHERE status='pending' GROUP BY sync_state;"
```

---

## AUDITORIA

Orquestração nativa sobre worker já auditado (ENI-41/E10.1-10.2). Sem mudança de contrato HTTP/auth.

**Veredito:** não escalar — testes Dart + verificação manual device.

---

## Arquivos alterados / criados

| Arquivo | Mudança |
|---------|---------|
| `lib/platform/sync_foreground_platform.dart` | **novo** |
| `lib/data/services/occurrence_sync_foreground_runner.dart` | **novo** |
| `lib/data/fakes/fake_sync_foreground_platform.dart` | **novo** |
| `android/.../SyncForegroundService.kt` | **novo** |
| `android/.../MainActivity.kt` | MethodChannel |
| `android/.../AndroidManifest.xml` | permissões + service |
| `android/.../res/values/strings.xml` | **novo** |
| `lib/app/di.dart` | registro runner + platform |
| `lib/presentation/bootstrap/app_bootstrap_screen.dart` | runner |
| `lib/presentation/capture/occurrence_draft_form_screen.dart` | runner |
| `lib/presentation/capture/capture_home_screen.dart` | runner |
| `test/data/services/occurrence_sync_foreground_runner_test.dart` | **novo** — 3 testes |
| `.cursor/docs/last_executed_task.md` | este relatório |
