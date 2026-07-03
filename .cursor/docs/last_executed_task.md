# Última tarefa executada — ENI-60: câmera "pega-tudo"

**Status: implementado** — verificação manual G56/G86 pendente

**Linear:** ENI-60 — capturas em sequência sem sair do preview

Data: 2026-07-03

---

## Escopo

Inverter o fluxo pós-captura: a câmera permanece no preview entre foto/vídeo; o form (categoria/observável/nota) só abre em **Concluir**. Multi-mídia (ENI-56) e pipeline de hash/GPS/mime/sort_order (ENI-50/56) intactos. Limite 5 min + wakelock por clipe (ENI-52) preservados.

**Fora de escopo:** abas/home (ENI-57), zoom (ENI-58), loading (ENI-59).

---

## Fluxo

```
Preview → capturar (foto ou vídeo) → anexa ao rascunho local_saved → permanece no preview
       → carrinho (contador + thumbnail da última) → revisar/remover
       → Concluir → form → Confirmar → fila (sync manual, ENI-49)
Sair sem concluir = rascunho local fora do sync (ENI-44)
```

| Ação | Comportamento |
|------|----------------|
| 1ª captura | `createDraftFromCapture` — cria ocorrência draft + mídia `sort_order=0` |
| N-ésima captura | `attachCaptureToDraft` — mesma occurrence, `sort_order` incremental |
| Toque no carrinho | Bottom sheet com lista; remove via `removeMediaFromDraft` |
| Concluir | Abre `OccurrenceDraftFormScreen` |
| Confirmar no form | `confirmDraft` → `pending` na fila; limpa rascunho ativo no preview |
| Voltar do form sem confirmar | Rascunho ativo permanece; pode capturar mais |

---

## Implementação

| Arquivo | Mudança |
|---------|---------|
| `lib/presentation/capture/capture_home_screen.dart` | Rascunho ativo (`_activeDraftId` + `_draftMedia`); não navega ao capturar; carrinho + Concluir em overlay; sheet de revisão/remoção |
| `lib/presentation/capture/in_app_capture_controls.dart` | `onCaptureComplete` assíncrono; `onTap` sempre ativo (avalia `_canPress` no toque); wakelock `disable` fire-and-forget (evita shutter morto após 1º vídeo) |
| `lib/presentation/capture/in_app_capture_screen.dart` | Callback assíncrono compatível |
| `lib/data/services/capture_occurrence_service.dart` | `isDraft(occurrenceId)` — detecta se form confirmou |
| `lib/data/fakes/fake_camera_source.dart` | Paths únicos por clipe de vídeo (2º, 3º…) |
| `test/presentation/capture/capture_flow_test.dart` | Fluxo pega-tudo + regressões atualizadas |

### Correção colateral (shutter após 1º vídeo)

`await WakelockPlus.disable()` no `finally` do stop não completava de forma confiável em testes (e podia atrasar o release de `_busy` no device). O `disable` passou a ser fire-and-forget, como o `enable`. Além disso, o shutter não usa mais `onTap: _canPress ? handler : null` (ficava `null` se o rebuild com `_busy=false` fosse perdido).

---

## Testes (`flutter test` — 127 passed)

```
00:06 +127: All tests passed!
```

Cenários ENI-60:

- capturar 2 vídeos + 1 foto sem sair do preview → rascunho com 3 mídias, `sort_order` `[0,1,2]`
- remover 1 mídia do carrinho antes de concluir → rascunho com 2
- concluir → form → confirmar → mídias na fila (mesma occurrence)
- vídeo único anexa sem abrir form
- regressões: sync manual, add/remove no form, modo foto/vídeo

---

## Arquivos tocados

**Alterados:**

- `lib/presentation/capture/capture_home_screen.dart`
- `lib/presentation/capture/in_app_capture_controls.dart`
- `lib/presentation/capture/in_app_capture_screen.dart`
- `lib/data/services/capture_occurrence_service.dart`
- `lib/data/fakes/fake_camera_source.dart`
- `test/presentation/capture/capture_flow_test.dart`
- `.cursor/docs/last_executed_task.md`

---

## Verificação manual G56 / G86 (aceite — pendente)

1. Gravar vídeo → volta ao preview (não vai pro form)
2. Gravar 2º vídeo → tirar 1 foto
3. Carrinho mostra **3** (thumbnail da última)
4. Toque no carrinho → remover 1 mídia → contador **2**
5. **Concluir** → form → **Confirmar**
6. Postgres: N linhas `occurrence_media`, mesma `occurrence_id`; Storage: N objetos
7. Sair sem concluir: rascunho local, fora da fila de sync

---

## Auditoria

**Não escalada.** UI/fluxo sobre pipeline ENI-50/56 já pronto. Sem alteração de modelo Drift, serializer ou fila de sync — apenas `isDraft` (leitura de status) e apresentação do rascunho multi-mídia no preview. Report + testes + device bastam.
