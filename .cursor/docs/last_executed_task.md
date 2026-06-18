# Última tarefa executada — P0 E9: defaults `title`/`description` no confirm

**Status: implementado** — verificação manual G56 pendente

**Linear:** épico **E9 — Captura capture-first** (criar issue com o ID que você usar no board; sugestão de título abaixo).

Data: 2026-06-18

---

## Posicionamento Linear (copiar ao criar issue)

| Campo | Valor |
|-------|--------|
| **Épico** | E9 — Captura capture-first (`docs/sentinel-scope.md` §3.2) |
| **Título** | Confirm sem nota: defaults de `title` e `description` (foto/áudio/vídeo) |
| **Prioridade** | P0 |
| **Labels** | `capture`, `sync`, `bug`, `offline-first`, `contract-api` |
| **Relação** | Bloqueador de sync — corrige 422 `validation:A descrição é obrigatória`; **não** é ENI-41/42 |
| **Fora de escopo** | + outra mídia, aba rascunhos, preview UX P1, alterar API |

**Descrição:** Operador pode enviar só mídia (nota opcional na UI). API exige `description` e `title` não vazios. `confirmDraft` agora preenche defaults por `mediaType` (`image` / `audio` / `video`) quando a nota está vazia.

---

## Implementação

| Arquivo | Função |
|---------|--------|
| `lib/core/capture/occurrence_confirm_text.dart` | `resolveOccurrenceConfirmText()` — nota trim ou defaults por mídia |
| `lib/data/services/capture_occurrence_service.dart` | `confirmDraft` busca mídia primária e aplica helper |
| `lib/data/repositories/occurrence_repository.dart` | `getPrimaryMedia()` — primeiro item por `sort_order` |

### Defaults (nota vazia)

| `mediaType` | `description` | `title` |
|-------------|---------------|---------|
| `image` | Registro fotográfico | Ocorrência |
| `audio` | Registro de áudio | Ocorrência |
| `video` | Registro de vídeo | Ocorrência |
| outro/ausente | Registro de ocorrência | Ocorrência |

`updateDraftForm` continua gravando a nota crua no rascunho; defaults **somente no confirm**.

### Testes

- `test/core/capture/occurrence_confirm_text_test.dart`
- `test/data/services/capture_occurrence_service_test.dart` — confirm sem nota (image + audio)

---

## Verificação manual G56 (aceite)

1. Device com `.env` apontando para backend de dev.
2. Capturar foto **sem** preencher nota no form.
3. Confirmar → sync (botão ou FGS se ENI-42 commitado).
4. **Esperado:** Postgres com `description` = `Registro fotográfico` (ou tipo correspondente); sem `failed_reason` `validation:` no Drift.
5. Repetir com nota preenchida → `description` = texto da nota.

---

## Backlog futuro (não neste ticket)

- E9 — Anexar múltiplas mídias à mesma ocorrência (+ outra captura)
- E9 — Tela/lista de rascunhos pendentes de confirmar
- P1 — Preview/copy unificada na home (foto/vídeo/áudio)
