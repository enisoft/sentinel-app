# Última tarefa executada — ENI-57: home com 2 abas + FAB de captura

**Status: implementado** — verificação manual G86 pendente

**Linear:** ENI-57 — nova home com abas Ocorrências / Tasks e captura via FAB

Data: 2026-07-03

---

## Escopo

Navegação/UI apenas. Home deixa de ser a câmera: abas + FAB abrem o fluxo pega-tudo (ENI-60). Badge e “Sincronizar agora” (ENI-49) migram para a aba Ocorrências.

**Fora de escopo:** Tasks de verdade (E7/inbox), zoom (ENI-58), loading (ENI-59), contrato/persistência/auth.

---

## Fluxo

```
Login → bootstrap → Home (aba Ocorrências)
  → FAB "Adicionar ocorrência" → captura pega-tudo (ENI-60)
       → Concluir → form → Confirmar → pop para lista (ocorrência aparece)
  → Aba Tasks → placeholder "Em breve" (sem API)
```

| Elemento | Comportamento |
|----------|----------------|
| Aba Ocorrências | Lista local Drift (draft + pending + synced); badge pendentes; botão sync (desabilitado com fila vazia) |
| Rascunho na lista | Rótulo "Não confirmada"; **não** entra no badge de pendentes (ENI-44) |
| Pendente / sincronizada | "Pendente" / "Sincronizada" (e Falha / Sincronizando conforme `SyncState`) |
| Aba Tasks | Placeholder "Em breve" — sem popular, sem chamar API |
| FAB | Abre `CaptureHomeScreen`; ao confirmar, volta à lista e recarrega |

---

## Implementação

| Arquivo | Mudança |
|---------|---------|
| `lib/presentation/home/home_screen.dart` | Shell: BottomNavigationBar (Ocorrências / Tasks), FAB, logout, aviso de catálogo |
| `lib/presentation/home/occurrences_tab.dart` | Lista local + badge/botão sync migrados da capture-home |
| `lib/presentation/home/tasks_tab.dart` | Placeholder "Em breve" |
| `lib/presentation/capture/capture_home_screen.dart` | Só fluxo de captura; sem badge/sync/logout; pop ao confirmar (se `canPop`) |
| `lib/presentation/bootstrap/app_bootstrap_screen.dart` | Destino pós-bootstrap: `HomeScreen` (não câmera) |
| `lib/data/repositories/occurrence_repository.dart` | `listAll()` — ocorrências locais por `createdLocalAt` desc |
| `test/presentation/home/home_screen_test.dart` | Abas, FAB, lista/rótulos, badge sem contar draft |
| `test/presentation/capture/capture_flow_test.dart` | Sync na home; FAB → captura → lista |
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | Bootstrap cai na home, não na câmera |

---

## Testes (`flutter test` — 134 passed)

```
00:08 +134: All tests passed!
```

Cenários ENI-57:

- abas: Ocorrências (lista/sync) e Tasks ("Em breve")
- FAB abre captura pega-tudo
- confirmar via FAB volta à lista com badge e item "Pendente"
- rascunho na lista como "Não confirmada", fora do badge (ENI-44)
- botão sync desabilitado com fila vazia; manual sync limpa badge
- bootstrap → `home_screen`, sem `capture_button`

---

## Arquivos tocados

**Novos:**

- `lib/presentation/home/home_screen.dart`
- `lib/presentation/home/occurrences_tab.dart`
- `lib/presentation/home/tasks_tab.dart`
- `test/presentation/home/home_screen_test.dart`

**Alterados:**

- `lib/presentation/capture/capture_home_screen.dart`
- `lib/presentation/bootstrap/app_bootstrap_screen.dart`
- `lib/data/repositories/occurrence_repository.dart`
- `test/presentation/capture/capture_flow_test.dart`
- `test/presentation/bootstrap/app_bootstrap_screen_test.dart`
- `.cursor/docs/last_executed_task.md`

---

## Verificação manual G86 (aceite — pendente)

1. Login → cai na home (aba Ocorrências, **não** na câmera)
2. FAB → captura pega-tudo → concluir → volta pra lista, ocorrência aparece
3. Aba Tasks → "Em breve"
4. Badge de pendentes + botão sync na aba Ocorrências; botão desabilitado com fila vazia

---

## Auditoria

**Não escalada.** Navegação/UI; não toca contrato, persistência de sync nem auth. Report + testes + device bastam.
