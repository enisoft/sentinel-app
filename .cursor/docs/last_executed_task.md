# ENI-78 — Retomar rascunho + lista navegável

**Tipo:** implementação FE (UI/navegação sobre dados locais)  
**Data:** 2026-07-04  
**Branch:** working tree

---

## Resumo

Lista de ocorrências (aba Ocorrências, ENI-57) agora é **navegável**: toque em rascunho abre o form editável; toque em confirmada/sincronizada abre detalhes read-only. O form **reidrata** categoria, observável, nota e zona ao reabrir um rascunho existente (além de mídias e zonas do operador).

---

## Implementação

### 1. Lista navegável (`occurrences_tab.dart`)

| Comportamento | Destino |
|---------------|---------|
| Toque em **RASCUNHO** (`status = draft`) | `OccurrenceDraftFormScreen(occurrenceId)` |
| Toque em **CONFIRMADA** / sincronizada | `OccurrenceDetailScreen(occurrenceId)` read-only |

**Distinção visual:**
- Rascunho: ícone `edit_note`, badge âmbar `Rascunho · {id6}`
- Confirmada: ícone `check_circle_outline`, badge cinza com id curto
- Recarrega lista ao voltar de qualquer tela (`_load()` após `Navigator.pop`)

### 2. Reidratação do form (`occurrence_draft_form_screen.dart`)

Novo `_loadDraft()` unifica carga de:
- mídias (`listDraftMedia`)
- zonas do operador (`/me` cache)
- **campos salvos** do registro Drift: `categoryId`, `observableId`, `zonaId`, `description` (nota)

Correção: dropdowns de categoria/observável usam `value:` (não `initialValue:`) para refletir estado após carga assíncrona.

`_syncDraft()` só dispara default de zona em rascunho **novo** (sem `zonaId` salvo).

### 3. Detalhes read-only (`occurrence_detail_screen.dart` — novo)

Exibe sem edição:
- mídias (thumbnails horizontais)
- estado de sync (`occurrenceListStatusLabel`)
- data/hora, zona, categoria, observável, nota, id curto

Resolve nomes de catálogo e zona via `CatalogRepository` + cache de `/me`.

### 4. Retomar rascunho

Fluxo ENI-60 mantido: adicionar/remover mídia no form → Confirmar → `status = pending` → fila de sync.

---

## Arquivos alterados / criados

| Arquivo | Ação |
|---------|------|
| `lib/presentation/capture/occurrence_draft_form_screen.dart` | modificado — `_loadDraft()`, `OccurrenceRepository` injetável |
| `lib/presentation/home/occurrences_tab.dart` | modificado — navegação + visual rascunho vs confirmada |
| `lib/presentation/home/occurrence_detail_screen.dart` | **novo** — detalhes read-only |
| `test/presentation/capture/occurrence_draft_resume_test.dart` | **novo** — reidratação + confirm enfileira |
| `test/presentation/home/home_screen_test.dart` | modificado — navegação lista + badge rascunho |

---

## Testes

```
flutter test
00:07 +170: All tests passed!
```

| Teste | Verifica |
|-------|----------|
| `occurrence_draft_resume_test` — repopulates | categoria, observável, nota, zona, mídias ao reabrir |
| `occurrence_draft_resume_test` — confirm enqueues | retomar → confirmar → `pending` + fila |
| `home_screen_test` — tap draft/synced | roteia form vs detalhes read-only |
| Suite completa | 170 testes verdes (+3 novos, baseline anterior 167) |

---

## Verificação manual (device G86)

1. Capturar 2 mídias + categoria/observável + nota → **SAIR** sem concluir.
2. Abrir na lista → form com **TUDO** (mídias + categoria + observável + nota + zona).
3. Adicionar 1 mídia → concluir → sincronizar → Postgres com 3 mídias e campos corretos.
4. Abrir ocorrência sincronizada → detalhes read-only (sem botão Confirmar).

---

## AUDITORIA

Não exigida — UI/navegação sobre dados locais; não altera contrato/sync/auth.

---

*Implementação ENI-78 concluída.*
