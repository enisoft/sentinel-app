# Última tarefa executada — ENI-42: FGS — fila completa + notificação honesta

**Status: implementado** — verificação manual G56 pendente

**Linear:** ENI-42 — Foreground Service (bugs pós-verificação device G56)

Data: 2026-07-02

---

## Posicionamento Linear

| Campo | Valor |
|-------|--------|
| **Issue** | ENI-42 |
| **Título** | FGS: drenar fila inteira + notificação reflete rede |
| **Prioridade** | P0 (Bug 1 crítico) |
| **Labels** | `sync`, `foreground-service`, `bug`, `offline-first` |
| **Relação** | Corrige ENI-41/42 pós-G56; guard ENI-41 mantido (ciclos concorrentes, não itens) |
| **Fora de escopo** | UIDT, política Wi-Fi, contrato API, auditoria fundação |

---

## Causa raiz (Bug 1)

1. **`processPending`** capturava a fila uma única vez — ocorrências confirmadas *durante* o ciclo ficavam de fora.
2. **`runIfPending`** chamava **`syncNow()` uma vez**; chamadas concorrentes (cada confirm dispara `unawaited(runIfPending)`) eram descartadas pelo guard ENI-41 sem re-disparo após o ciclo.

## Causa raiz (Bug 2)

Notificação Android era estática (`Upload e envio em andamento.`) — não refletia falha de rede (`ApiException(0)`).

---

## Implementação

| Arquivo | Mudança |
|---------|---------|
| `lib/data/services/occurrence_sync_service.dart` | Loop com re-fetch da fila + `attemptedThisCycle`; `hadNetworkFailure` em `OccurrenceSyncResult` |
| `lib/data/services/occurrence_sync_foreground_runner.dart` | Drain até esvaziar (ou sem progresso/rede); coalescência de chamadas concorrentes; updates de notificação |
| `lib/core/sync/sync_foreground_notification_text.dart` | Textos: `Enviando X de N` / `X pendente(s), aguardando conexão` |
| `lib/core/sync/sync_network_error.dart` | Helper `isSyncNetworkError` (ENI-38) |
| `lib/platform/sync_foreground_platform.dart` | `updateForegroundNotification(title, text)` |
| `android/.../SyncForegroundService.kt` | `ACTION_UPDATE` para atualizar notificação em runtime |
| `android/.../MainActivity.kt` | Method channel `updateForegroundNotification` |
| `lib/data/remote/media_upload_exception.dart` | `isNetworkError` quando `statusCode == null` |

### Comportamento

- **Guard ENI-41** continua em `DefaultOccurrenceSyncCoordinator.syncNow` — impede ciclos paralelos, não itens dentro do ciclo.
- **FGS runner** serializa drains via `_activeDrain`; loops `syncNow` até fila vazia, falha de rede ou zero progresso.
- **Offline:** notificação → `Ocorrências pendentes` / `N pendente(s), aguardando conexão`; FGS permanece se ainda houver pendentes.
- **Online:** `Sincronizando ocorrências…` / `Enviando X de N` só durante upload/sync real.

---

## Testes (`flutter test` — 96 passed)

- `processPending syncs three or more occurrences in one cycle` (N=4)
- `processPending picks up occurrences added during drain`
- `runIfPending` — drain multi-item, coalescência concorrente
- `occurrence_sync_foreground_notification_test.dart` — waiting vs sending
- `sync_foreground_notification_text_test.dart`

```
00:05 +96: All tests passed!
```

---

## Verificação manual G56 (aceite — refazer)

### Bug 1 — fila completa
1. Capturar e confirmar **3–4** ocorrências (com mídia).
2. Minimizar o app imediatamente.
3. **Esperado:** todas sobem em background (Postgres + Storage); fila Drift vazia; notificação some.

### Bug 2 — notificação honesta
1. Modo avião / sem rede.
2. Capturar e confirmar ocorrências.
3. **Esperado:** push mostra `N pendente(s), aguardando conexão` — **não** "upload e envio em andamento".
4. Religar rede → sync automático (confirm ou botão) → notificação some ao esvaziar.

### Regressão
- Rascunhos (`draft`) continuam fora da fila (ENI-44).
- Botão "Sincronizar agora" na home ainda funciona.

---

## Auditoria

Não exigida — correção de loop + UX de notificação. Guard ENI-41 intacto; sem mudança de contrato/auth/persistência.
