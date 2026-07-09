# ENI-105 (ajuste) — calibrar timeouts de sync + retry rápido

**Tipo:** Resiliência de sync / cold start  
**Data:** 2026-07-09  
**Branch:** working tree

---

## Objetivo

Cold start com servidor off levava ~1min até avisar (408 em 30s). Separar timeout de **conexão inicial** (curto) do **stall de upload TUS** (paciente) e adicionar retry rápido antes de mostrar erro.

---

## Implementação

| # | Item | Estado |
|---|------|--------|
| 1 | Timeout curto (~10s) em GET `/me` e POST `/occurrences/sync` | **Feito** |
| 2 | Stall TUS mantido em 25s (sem alteração) | **Feito** |
| 3 | Retry automático 1x com backoff ~3s em falha de rede/timeout no primeiro contato | **Feito** |
| 4 | Demais endpoints (catálogo, mensagens) mantêm timeout padrão 30s | **Feito** |
| 5 | Mensagem pós-retry: "Sem acesso ao servidor…" | **Feito** |
| 6 | Pior caso ~23s (10s + 3s + 10s), não ~1min | **Feito** |

### Distinção de timeouts

| Cenário | Timeout | Comportamento |
|---------|---------|---------------|
| Primeiro contato (`/me`, `/occurrences/sync`) | 10s | Falha rápido se servidor inacessível |
| Retry de primeiro contato | +3s backoff, 1 tentativa | UI pode ficar em "Sincronizando…" |
| Upload TUS em progresso | 25s stall por inatividade | Upload lento mas progredindo não aborta |
| Catálogo / mensagens | 30s (inalterado) | Não é "primeiro contato" |

### Arquivos alterados

| Arquivo | Ação |
|---------|------|
| `lib/core/network/initial_contact_retry.dart` | novo — retry 1x com backoff |
| `lib/data/remote/api_client.dart` | timeout curto + retry em `/me` e `/occurrences/sync` |
| `lib/core/config/app_config.dart` | `SYNC_INITIAL_CONTACT_TIMEOUT_SECONDS`, `SYNC_INITIAL_CONTACT_RETRY_BACKOFF_SECONDS` |
| `lib/core/bootstrap/bootstrap_messages.dart` | mensagem "Sem acesso ao servidor…" |
| `.env.example` | documenta novas vars |
| `test/core/network/initial_contact_retry_test.dart` | novo |
| `test/data/remote/api_client_test.dart` | timeout curto, retry, sem retry em sucesso |
| `test/core/config/app_config_test.dart` | parsing env vars |

---

## Testes

```
flutter test
00:11 +240: All tests passed!
```

Cobertura ajuste ENI-105:
- timeout curto em `/me` → 2 tentativas em ~100–250ms (teste com mocks);
- 1ª falha rede → 2ª ok → sincroniza sem erro;
- 1ª ok → sem retry;
- `postOccurrencesSync` retry 1x em rede;
- stall TUS intacto (testes anteriores ENI-105).

Status: **240/240 verdes**.

---

## Verificação manual (pendente — G86 via Tailscale)

1. Servidor OFF → abrir app → em ~20–25s (com retry) vem "sem acesso", não 1min.
2. Servidor volta entre as tentativas → sincroniza sem erro.
3. Upload de vídeo grande em rede lenta → não aborta por engano.

---

## Commit

```
fix: calibrar timeouts sync + retry rápido (ENI-105)
```

Push/Done após G86.

---

# ENI-105 — timeout de inatividade no upload TUS (sync trava quando servidor some)

**Tipo:** Resiliência de sync / upload  
**Data:** 2026-07-08  
**Branch:** working tree

---

## Objetivo

Evitar que upload TUS fique preso indefinidamente em conexão half-open (servidor some no meio) — UI não pode ficar em "Sincronizando…" para sempre.

---

## Implementação

| # | Item | Estado |
|---|------|--------|
| 1 | Stall timeout (inatividade, não duração total) via `TusUploadStallGuard` + `onProgress` | **Feito** |
| 2 | `SentinelTusClient` com `HttpClient.idleTimeout` + `abort()` do socket | **Feito** |
| 3 | Stall → `MediaUploadException` com `isNetworkError=true` (retry/backoff existente) | **Feito** |
| 4 | Coordinator sai de `syncing`, `hadNetworkFailure`, mensagem "Conexão indisponível" | **Feito** |
| 5 | Timeout global de ciclo no coordinator (`processPending`) e foreground runner (drain) | **Feito** |
| 6 | `recoverFromExternalTimeout()` libera guard após timeout externo no drain | **Feito** |
| 7 | Config via `.env`: `TUS_UPLOAD_STALL_TIMEOUT_SECONDS` (25), `SYNC_DRAIN_CYCLE_TIMEOUT_MINUTES` (30) | **Feito** |

### Abordagem técnica (stall, não total)

- **Timer por progresso:** `TusUploadStallGuard` reinicia timer a cada callback `onProgress` do `tus_client_dart`; sem progresso por N segundos → `pauseUpload()` + `abort()` do socket.
- **Idle no socket:** `SentinelTusClient` usa `HttpClient.idleTimeout = stallTimeout` — fecha conexão sem tráfego de bytes (cobre `client.send()` pendurado em half-open onde `onProgress` ainda não disparou).
- Upload lento mas **progredindo** não é abortado: bytes fluindo mantêm conexão viva; cada chunk concluído reinicia o timer.

### Arquivos alterados

| Arquivo | Ação |
|---------|------|
| `lib/data/remote/tus_upload_stall_guard.dart` | novo — monitor de inatividade |
| `lib/data/remote/sentinel_tus_client.dart` | novo — TusClient com abort + idleTimeout |
| `lib/data/remote/tus_media_uploader.dart` | stall guard + SentinelTusClient |
| `lib/core/config/app_config.dart` | env vars de timeout |
| `lib/data/services/occurrence_sync_coordinator.dart` | timeout de ciclo + recover |
| `lib/data/services/occurrence_sync_foreground_runner.dart` | timeout de drain + recover |
| `lib/data/fakes/fake_occurrence_sync_coordinator.dart` | `recoverFromExternalTimeout` |
| `lib/app/di.dart` | injeta timeouts do config |
| `.env.example` | documenta novas vars |
| `test/data/remote/tus_upload_stall_guard_test.dart` | novo |
| `test/data/services/occurrence_sync_coordinator_test.dart` | stall + cycle timeout |
| `test/data/services/occurrence_sync_service_test.dart` | stall network failure |
| `test/data/services/occurrence_sync_foreground_runner_test.dart` | drain cycle timeout |
| `test/core/config/app_config_test.dart` | parsing env vars |

---

## Testes

```
flutter test
00:08 +231: All tests passed!
```

Cobertura ENI-105:
- sem progresso por `STALL_TIMEOUT` → aborta → `MediaUploadException(network)` → sai de syncing;
- progresso contínuo reinicia timer → não aborta;
- stall no service → `hadNetworkFailure`;
- timeout de ciclo no coordinator encerra `syncing`;
- timeout de drain no foreground runner → notificação "aguardando conexão".

Status: **231/231 verdes** (era 222).

---

## Verificação manual (pendente — G86 via Tailscale)

1. Iniciar sync de vídeo → matar servidor no meio → em ~25s UI sai de "Sincronizando" para "aguardando conexão"/erro; item volta pra fila.
2. Reativar servidor → sync retoma (TUS offset) e conclui.
3. Upload longo normal (vídeo grande, rede ok) → conclui sem abortar por engano.

---

## Auditoria

Não escalada — timeout isolado no uploader + transição de estado já coberta por testes; máquina de estados do coordinator só ganhou timeout/recover (não-trivial mas contido).

---

## Commit (preparado — push após G86)

```
fix: timeout de inatividade no upload TUS (ENI-105)
```

---

# ENI-86 — feedback de captura discreto (flash + haptic, sem som)

**Tipo:** UX de captura discreta  
**Data:** 2026-07-08  
**Branch:** working tree

---

## Objetivo

Dar confirmação imediata de captura sem denunciar operação no ambiente:

- **Sem som** em qualquer ponto.
- **Sem flash/torch de hardware** (sem LED da câmera).
- Feedback local no app: **flash branco de tela + haptic leve** no toque.

---

## Implementação

| # | Item | Estado |
|---|------|--------|
| 1 | Overlay branco breve (~120ms, fade out) sobre preview no toque de foto | **Feito** |
| 2 | Haptic leve no toque de foto (`lightImpact`) | **Feito** |
| 3 | Mesmo feedback no início de vídeo (flash + `lightImpact`) | **Feito** |
| 4 | Mesmo feedback no fim de vídeo (flash + `selectionClick`) | **Feito** |
| 5 | Disparo imediato no toque (antes/paralelo ao processamento posterior) | **Feito** |
| 6 | Sem alterar fluxo pega-tudo (ENI-60), sem introduzir áudio/torch | **Feito** |

### Detalhes técnicos

- `InAppCaptureControls` passa a emitir `CaptureFeedbackEvent` no instante do toque:
  - `photo`, `videoStart`, `videoStop`.
- `CaptureHomeScreen` e `InAppCaptureScreen`:
  - recebem o evento;
  - disparam `FadeTransition` em overlay branco (`capture_feedback_flash_overlay`);
  - disparam haptic sem bloquear captura (`unawaited(HapticFeedback...)`).
- O feedback ocorre no **UI thread do toque**, enquanto captura/hash/GPS seguem assíncronos.

### Arquivos alterados

| Arquivo | Ação |
|---------|------|
| `lib/presentation/capture/in_app_capture_controls.dart` | novo callback/evento de feedback imediato |
| `lib/presentation/capture/capture_home_screen.dart` | flash overlay + haptic no fluxo pega-tudo |
| `lib/presentation/capture/in_app_capture_screen.dart` | flash overlay + haptic no fluxo de anexar mídia |
| `test/presentation/capture/capture_flow_test.dart` | widget test de flash/haptic foto + vídeo |

---

## Testes

```
flutter test
00:08 +222: All tests passed!
```

Cobertura adicionada ENI-86:
- feedback visual aparece e some após toque de foto;
- início/fim de vídeo disparam feedback visual + haptic;
- sem dependência de áudio/som/torch no fluxo de feedback.

Status: **222/222 verdes**.

---

## Verificação manual (pendente — G86)

1. Tocar foto → pisca branco + vibração curta, sem som e sem LED.
2. Iniciar vídeo → feedback; parar → feedback.
3. Capturar 3-4 em sequência (pega-tudo) → feedback em cada captura sem travar.

---

## Auditoria

Não exigida (UX; sem alteração de contrato de captura/integridade/sync).

---

# ENI-101 — aviso de logout com pendências + badge de outro operador

**Tipo:** UX / multi-operador no device (complemento ENI-97)  
**Data:** 2026-07-08  
**Branch:** working tree

---

## Objetivo

Dois ajustes de UX sobre a fila global de sync no device:

1. **Logout com pendências próprias** — diálogo opcional (não bloqueia offline).
2. **Badge/mensagem** — distinguir pendências do operador logado vs capturas de outro operador no aparelho.

---

## Implementação

| # | Item | Estado |
|---|------|--------|
| 1 | Contagem por uid em `SyncQueueRepository` (próprias / outras / badge próprio + check-ins) | **Feito** |
| 2 | Diálogo no logout (`HomeScreen`) quando há capturas próprias não sincronizadas | **Feito** |
| 3 | Badge laranja `N pendente(s)` só para pendências próprias | **Feito** |
| 4 | Mensagem separada `N captura(s) de outro operador neste aparelho — sincronizar` | **Feito** |
| 5 | Sem expor detalhes das capturas de outro operador | **Feito** |
| 6 | Sync de outro operador continua permitido (preserva `reported_by`) | **Feito** (sem alteração no worker) |

### Comportamento — logout

- Contagem = capturas pendentes com `reported_by = uid` logado (não inclui as de outro operador).
- **Sincronizar agora** → dispara `OccurrenceSyncForegroundRunner.runIfPending()`, permanece logado.
- **Sair mesmo assim** → `signOut()`.
- **Cancelar** → fecha o diálogo.
- Sem pendências próprias → logout direto.

### Comportamento — badges (`OccurrencesTab`)

- **Próprias** (`reported_by == uid` + check-ins locais): badge laranja `pending_sync_badge`.
- **Outro operador** (`reported_by != uid`, inclui órfãs): badge cinza `other_operator_pending_badge`.
- Se ambas existem, mostra as duas linhas; se só próprias, só o badge normal.

### Arquivos alterados / criados

| Arquivo | Ação |
|---------|------|
| `lib/core/sync/sync_pending_messages.dart` | **novo** — textos UI |
| `lib/data/repositories/sync_queue_repository.dart` | contagens por operador |
| `lib/presentation/home/home_screen.dart` | diálogo de logout |
| `lib/presentation/home/occurrences_tab.dart` | badges separados |
| `test/data/repositories/repositories_test.dart` | teste contagem ENI-101 |
| `test/presentation/home/home_screen_test.dart` | logout + badges |
| `test/presentation/capture/capture_flow_test.dart` | `reportedBy` nos seeds |
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | `reportedBy` + uid perfil |
| `test/presentation/auth/auth_gate_offline_test.dart` | perfil cache = uid auth |
| `test/presentation/capture/occurrence_draft_form_zone_test.dart` | FakeAuth + uid perfil |
| `test/presentation/capture/occurrence_draft_resume_test.dart` | FakeAuth + uid perfil |

---

## Testes

```
flutter test
00:09 +221: All tests passed!
```

**221/221 verdes** (+6 novos ENI-101; +5 correções de uid de perfil em testes pós ENI-97).

Cobertura ENI-101:
- logout com N pendentes próprias → diálogo; cancelar / sair / sincronizar
- logout sem pendências próprias (mesmo com pendência de outro) → logout direto
- badge separa "minhas" de "de outro operador"
- contagem cruzada: próprias ∩ outras = ∅

---

## Verificação manual (pendente — G86)

1. Capturar, não sincronizar, logout → aviso com contagem certa.
2. Login B com pendência do A no device → mensagem "de outro operador", não "suas".
3. Sincronizar as de outro → sobem preservando autoria.

---

## Auditoria

Não exigida (UX sobre dados já escopados; não altera contrato/auth/autoria).

---

# ENI-97 — reported_by na captura + sync + filtro por dono

**Tipo:** feature / isolamento multi-operador no device  
**Data:** 2026-07-08  
**Branch:** working tree

---

## Objetivo

Carimbar o operador dono (`reported_by`) na captura local, enviar no payload de sync (backend respeita na 1ª gravação, imutável depois) e filtrar a lista para cada operador ver só as suas ocorrências.

---

## Implementação

| # | Item | Estado |
|---|------|--------|
| 1 | Drift: coluna `reported_by` (nullable) + migration schema v8 | **Feito** |
| 2 | Captura: `reported_by = uid` da sessão no `createOccurrence` | **Feito** |
| 3 | Serializer: `reported_by` no JSON de sync quando presente | **Feito** |
| 4 | Lista (`occurrences_tab`): `listForOperator(uid)` em vez de `listAll()` | **Feito** |
| 5 | Legadas sem `reported_by`: órfãs — não aparecem na lista de ninguém | **Feito** (aviso UI = ENI-101) |

### Decisão — ocorrências legadas (pré ENI-97)

- `reported_by = null` → **órfã**
- **Não** atribuir ao operador logado na migration (risco de dono errado)
- Permanecem no Drift; **não** aparecem na lista de nenhum operador
- `OccurrenceRepository.countOrphanOccurrences()` disponível para aviso futuro
- Sync: serializer omite `reported_by` quando null (backend pode derivar do token nesse caso legado)

### Arquivos alterados / criados

| Arquivo | Ação |
|---------|------|
| `lib/data/local/tables/occurrences.dart` | coluna `reportedBy` |
| `lib/data/local/app_database.dart` | schema v8 + migration |
| `lib/domain/gateways/auth_gateway.dart` | `currentUserId` |
| `lib/data/gateways/supabase_auth_gateway.dart` | `currentUser?.id` |
| `lib/data/fakes/fake_auth_gateway.dart` | `userId` para testes |
| `lib/data/repositories/occurrence_repository.dart` | `reportedBy`, `listForOperator`, `countOrphanOccurrences` |
| `lib/data/services/capture_occurrence_service.dart` | carimbo na captura |
| `lib/data/sync/sync_payload_serializer.dart` | `reported_by` no payload |
| `lib/presentation/home/occurrences_tab.dart` | filtro por dono |
| `lib/app/di.dart` | wiring CaptureOccurrenceService |
| `.cursor/rules/sentinel-app.md` | regra atualizada (reported_by no payload) |
| `test/data/repositories/occurrence_reported_by_test.dart` | **novo** |
| `test/presentation/home/home_screen_test.dart` | isolamento ENI-97 |
| `test/data/sync/sync_payload_serializer_test.dart` | expect `reported_by` |
| `test/data/gateways/sync_gateway_http_test.dart` | expect `reported_by` |
| `test/data/services/capture_occurrence_service_test.dart` | assert stamp |
| `test/presentation/capture/capture_flow_test.dart` | FakeAuthGateway no DI |
| `.cursor/docs/audit_2026-07-08_eni-97.md` | **novo** |

---

## Testes

```
flutter test
00:08 +215: All tests passed!
```

**215/215 verdes** (+6 novos).

Cobertura ENI-97:
- captura grava `reported_by = uid` logado
- serializer inclui `reported_by` no payload
- `listForOperator` mostra só do uid; outro uid e órfãs ocultas
- widget test: lista esconde ocorrências de outro operador

---

## Verificação manual (pendente — G86)

1. Operador A captura 2 → aparecem pra A.
2. Logout. Login B → B **não** vê as de A; captura as suas.
3. B sincroniza → Postgres: ocorrências de A (se na fila) mantêm `reported_by=A`.
4. Login A de volta → vê as dele.

---

# Diag — sync travado quando servidor some

**Tipo:** investigação read-only (sem alteração de código)  
**Data:** 2026-07-08  
**Cenário reportado:** sync via rede instável; servidor (PC) ficou inacessível **no meio** (dormiu). App permaneceu em "Sincronizando…" indefinidamente, sem transitar para estado de falha/aguardando conexão.

---

## Respostas (arquivo:linha)

### 1. Timeout do `ApiClient` (`_requestTimeout`)

| Onde | Valor |
|------|-------|
| `lib/data/remote/api_client.dart:20` | default `Duration(seconds: 30)` — **30 s** |
| `lib/data/remote/api_client.dart:29` | campo `_requestTimeout` |
| `lib/data/remote/api_client.dart:140` | aplicado: `send(uri, headers).timeout(_requestTimeout)` |
| `lib/app/di.dart:158-159` | `ApiClient` instanciado **sem** override → herda 30 s |

**Conclusão:** requests JSON (`POST /occurrences/sync`, `/me`, catálogo, etc.) têm teto de **30 segundos**.

---

### 2. `TusMediaUploader` — timeout próprio?

**Não.** Nenhum `Duration` / `.timeout()` no upload TUS.

| Onde | O que faz |
|------|-----------|
| `lib/data/remote/tus_media_uploader.dart:81-88` | `TusClient(..., retries: 3, retryInterval: 2, retryScale: RetryScale.exponential)` — só retry em **exceção**, não timeout |
| `lib/data/remote/tus_media_uploader.dart:91-102` | `await client.upload(...)` — sem wrapper de timeout |
| `lib/data/remote/tus_media_uploader.dart:103-113` | captura `ProtocolException`, `SocketException`, `HttpException` — **não** captura `TimeoutException` |
| `tus_client_dart` 2.5.0 `lib/src/client.dart:27` | `getHttpClient() => http.Client()` — client HTTP cru |
| `tus_client_dart` `lib/src/client.dart:50,208,338` | `client.post`, `client.send`, `client.head` — **sem** `.timeout()` |

**O que interrompe a espera no TUS se o servidor para de responder no meio do upload?**

- **Connection refused / socket morto imediato** → `SocketException` → `MediaUploadException` (`tus_media_uploader.dart:109-110`) → tratado em `occurrence_sync_service.dart:115-121`.
- **Conexão TCP já aberta, servidor deixa de responder (PC dormiu)** → `client.send()` em `_performUpload` **fica bloqueado** até o SO encerrar o socket (keepalive TCP — tipicamente **minutos a horas**, não 30 s). Nenhum timeout de aplicação interrompe.
- Retries do TUS (`client.dart:272-288`) só disparam em **catch**; hang sem exceção **não** aciona retry.

**Herança:** upload TUS **não** herda o timeout de 30 s do `ApiClient`. São stacks HTTP independentes.

---

### 3. Estado "sincronizando" — timeout global de ciclo?

**Não.** Nenhum timeout global no coordinator nem no foreground runner.

| Componente | Comportamento |
|------------|---------------|
| `lib/data/services/occurrence_sync_coordinator.dart:47-93` | `syncNow()`: seta `syncing` (L51), `await processPending()` (L54), volta `idle` no `try`/`catch`/`finally` — duração = tempo de `processPending()` |
| `lib/data/services/occurrence_sync_foreground_runner.dart:43-107` | `_drainPendingQueue()`: loop `while pending > 0` (L54), cada iteração `await _coordinator.syncNow()` (L78) — sem `timeout` |
| `lib/core/sync/occurrence_sync_coordinator_state.dart:36-37` | `isSyncInProgress` = `status == syncing` **OU** `syncProgressCurrent/Total != null` |
| `occurrence_sync_foreground_runner.dart:52` | `reportSyncProgress` no **início** do drain |
| `occurrence_sync_foreground_runner.dart:105` | `clearSyncProgress` só no `finally` — **depois** que o drain termina |

**Conclusão:** o ciclo depende **inteiramente** do término de cada request (TUS sem teto; JSON com 30 s). Não há watchdog de ciclo.

---

### 4. Request pendurada além do timeout — volta a idle/erro?

**Depende da fase:**

| Fase | Timeout? | Se estoura | Se hang sem exceção |
|------|----------|------------|---------------------|
| JSON (`ApiClient`) | 30 s (`api_client.dart:140-146`) | `TimeoutException` → `ApiException(408)` → `occurrence_sync_service.dart:227-234` → `hadNetworkFailure`, `recordFailure`, coordinator `idle` | N/A (tem timeout) |
| Mídia TUS | **Nenhum** | `TimeoutException` **nunca** é lançado pelo uploader | `processPending()` **não retorna** → coordinator preso em `syncing` (`coordinator.dart:51`), `_running = true` (`L44-50`), progress não limpo (`foreground_runner.dart:105`) |

**Coordinator** tem `catch` genérico (`coordinator.dart:72-86`) e `finally` de segurança (`L87-91`), mas ambos só rodam **quando** `processPending()` completa. Hang = `finally` nunca executa.

**UI presa em "Sincronizando":**
- Botão/label: `occurrences_tab.dart:247-253` — `isSyncInProgress` true enquanto `syncing` ou progress ativo.
- Item na lista: `occurrences_tab.dart:396-399` — ocorrência em `mediaUploading` mostra "Sincronizando" (estado Drift não muda até `recordFailure`).

**Estado "sem acesso / aguardando conexão"** (texto real no app):
- Notificação FGS: `sync_foreground_notification_text.dart:14-15` — `"N pendente(s), aguardando conexão"`.
- Só aparece **após** `hadNetworkFailure == true` e o runner sair do loop (`foreground_runner.dart:86-94`).
- Se o hang ocorre no TUS, `hadNetworkFailure` **nunca** é setado → notificação permanece em `titleSending` / "Sincronizando ocorrências…" (`sync_foreground_notification_text.dart:5`).

---

### 5. Connection refused (rápido) vs hang (servidor não responde)

| Cenário | JSON (`ApiClient`) | TUS (`TusMediaUploader`) |
|---------|---------------------|--------------------------|
| **(a) Servidor recusa conexão** | `SocketException` / `ClientException` → `ApiException.network` (`api_client.dart:147-150`) — **rápido** | `SocketException` no POST/PATCH → `MediaUploadException(null, …)` (`tus_media_uploader.dart:109`) — **rápido** |
| **(b) Conexão abre, servidor não responde** | `.timeout(30s)` → `ApiException(408, isNetworkError: true)` (`api_client.dart:141-146`) | **Sem timeout** — `http.Client.send()` aguarda indefinidamente (limite = TCP do SO) |

**O app trata os dois no JSON?** Sim — refused e timeout viram `isNetworkError`, `hadNetworkFailure`, `recordFailure`, UI volta a idle com erro ou notificação "aguardando conexão".

**O app trata os dois no TUS?** Parcialmente — só **(a)**. Cenário **(b)** no meio do upload = **buraco**: nenhuma exceção, nenhum `hadNetworkFailure`, sync eterno.

---

## Diagnóstico — por que "Sincronizando" não terminou

**Causa raiz provável (cenário PC dormiu no meio):**

1. Sync estava na fase **`mediaUploading`** → `_gateway.uploadOccurrenceMedia` → `TusMediaUploader` → `TusClient.upload`.
2. Conexão TCP já estabelecida; ao dormir o PC, o socket fica **half-open** — não gera `SocketException` imediato.
3. `tus_client_dart` chama `client.send()` sem timeout (`client.dart:208`); o `await` **nunca resolve**.
4. `OccurrenceSyncService.processPending()` (`occurrence_sync_service.dart:89-90`) bloqueia em `_advanceMedia`.
5. `DefaultOccurrenceSyncCoordinator.syncNow()` (`coordinator.dart:54`) não retorna → `status` permanece `syncing`.
6. `OccurrenceSyncForegroundRunner` (`foreground_runner.dart:78`) não chega ao `break` por `hadNetworkFailure` nem ao `finally` que limpa progress.
7. UI: `isSyncInProgress` true (`coordinator_state.dart:36-37`); botão "Sincronizando…" (`occurrences_tab.dart:252-253`); notificação "Sincronizando ocorrências…" em vez de "aguardando conexão".

**Onde está (ou falta) o timeout:**

| Camada | Timeout | Gap |
|--------|---------|-----|
| `ApiClient` JSON | ✅ 30 s | — |
| `TusMediaUploader` / `tus_client_dart` | ❌ ausente | **gap principal** |
| Coordinator / ForegroundRunner | ❌ ausente | depende do worker; sem watchdog |
| `isSyncInProgress` via progress | — | progress só limpo no `finally` do runner; amplifica sensação de "preso" |

**Nota:** se o hang ocorresse na fase JSON (sem mídia pendente), o `ApiClient` deveria liberar em ~30 s e o app transitaria para idle + "aguardando conexão" na notificação. O sintoma "indefinido" aponta fortemente para **upload TUS sem timeout**.

---

## Ação

Nenhuma (investigação read-only). Correções ficam fora de escopo desta tarefa.
