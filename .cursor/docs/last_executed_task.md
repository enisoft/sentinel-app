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
