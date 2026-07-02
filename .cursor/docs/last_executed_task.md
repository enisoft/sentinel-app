# Última tarefa executada — ENI-49: Sync manual-first + badge de pendentes

**Status: implementado** — verificação manual G56 pendente

**Linear:** ENI-49 — Sync manual-first + badge de pendentes na home

Data: 2026-07-02

---

## Posicionamento Linear

| Campo | Valor |
|-------|--------|
| **Issue** | ENI-49 |
| **Título** | Sync manual-first + badge de pendentes na home |
| **Prioridade** | P1 |
| **Labels** | `sync`, `offline-first`, `ux` |
| **Relação** | Complementa ENI-41 (botão manual + watchPending); remove peso no login |
| **Fora de escopo** | Contrato API, fila, FGS runner, UIDT, auditoria fundação |

---

## Decisão

Sync **não** roda sozinho no login nem ao confirmar rascunho. O operador dispara via botão **"Sincronizar agora"** (ENI-41) ou FGS (quando o drain já está em andamento). Badge de pendentes compensa a falta de sync automático.

---

## Gatilhos de `runIfPending` — antes vs depois

| Gatilho | Antes (ENI-42) | Depois (ENI-49) |
|---------|----------------|-----------------|
| Cold start (`AppBootstrapScreen`) | Sim | **Não** |
| Confirmação de rascunho (`OccurrenceDraftFormScreen`) | Sim | **Não** |
| Botão "Sincronizar agora" (`CaptureHomeScreen`) | Sim | **Sim** |
| FGS (`OccurrenceSyncForegroundRunner`) | Só via `runIfPending` | Inalterado |

---

## Implementação

| Arquivo | Mudança |
|---------|---------|
| `lib/presentation/bootstrap/app_bootstrap_screen.dart` | Removido `runIfPending()` pós-bootstrap |
| `lib/presentation/capture/occurrence_draft_form_screen.dart` | Removido `unawaited(runIfPending())` pós-confirm |
| `lib/presentation/capture/capture_home_screen.dart` | Badge com destaque visual (`orange.shade700`, negrito, `Key('pending_sync_badge')`) |
| `lib/app/di.dart` | Parâmetro opcional `occurrenceSyncForegroundRunner` em `configureDependenciesForTesting` |
| `test/support/counting_occurrence_sync_foreground_runner.dart` | Helper de teste para contar chamadas |
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | Bootstrap não dispara sync com itens pendentes |
| `test/presentation/capture/capture_flow_test.dart` | Badge reativo, confirm sem auto-sync, botão manual |

### Badge na home

- Fonte: `OccurrenceSyncCoordinator.state.pendingCount` via `watchPending()` (ENI-41, exclui rascunhos ENI-44).
- **N > 0:** chip laranja com texto branco em negrito.
- **N == 0:** oculto.
- Atualiza ao confirmar captura (N sobe) e ao concluir sync manual (N zera).

---

## Testes (`flutter test` — 100 passed)

Novos/ajustados:
- `bootstrap does not call runIfPending automatically`
- `capture button creates draft` — badge ausente com draft
- `confirming form enqueues occurrence for sync` — badge `1 pendente(s)`; `syncState` permanece `localSaved` até sync manual
- `confirming form does not trigger automatic sync`
- `manual sync clears pending badge`
- `sync now button calls runIfPending`

```
00:12 +100: All tests passed!
```

---

## Verificação manual G56 (aceite)

1. Abrir app com itens pendentes → **não** sincroniza sozinho; badge mostra N.
2. Tocar "Sincronizar agora" → sincroniza → badge zera.
3. Capturar offline → confirmar → badge incrementa.
4. Capturar offline → sair sem confirmar (draft) → badge **não** conta.

---

## Auditoria

Não exigida — remoção de gatilhos automáticos + widget de contador; sem mudança de contrato/auth/persistência/FGS.
