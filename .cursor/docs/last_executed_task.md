# Última tarefa executada — ENI-55: content_hash no payload de sync

**Status: implementado** — verificação manual G56 pendente

**Linear:** ENI-55 — Enviar content_hash no sync de mídia

Data: 2026-07-02

---

## Posicionamento Linear

| Campo | Valor |
|-------|--------|
| **Issue** | ENI-55 |
| **Título** | App envia content_hash no sync |
| **Prioridade** | P1 |
| **Dependências** | ENI-50 (hash local), ENI-54 (backend aceita campo) |
| **Fora de escopo** | Fila, upload TUS, contrato de ocorrência |

---

## Decisão

`SyncPayloadSerializer` passa a incluir `content_hash` (SHA-256 hex lowercase, 64 chars) no bloco de cada mídia quando presente no SQLite local. Sem hash → campo omitido (backend aceita ausência). Nenhuma alteração em fila, upload ou demais campos do contrato.

---

## Implementação

| Arquivo | Mudança |
|---------|---------|
| `lib/data/sync/sync_payload_serializer.dart` | `content_hash` condicional em `serializeOccurrenceMedia` |
| `test/data/sync/sync_payload_serializer_test.dart` | Assert ausência sem hash; teste com hash 64 hex |

---

## Testes (`flutter test` — 105 passed)

Novos:
- `includes content_hash when media has hash`
- Assert `content_hash` ausente no teste de contrato existente (mídia sem hash)

```
00:04 +105: All tests passed!
```

---

## Verificação manual G56 (aceite)

| # | Cenário | Evidência |
|---|---------|-----------|
| 1 | Capturar foto → sincronizar → `occurrence_media.content_hash` no Postgres = hash local do device | _pendente_ |

---

## Auditoria

**Não aplicável** — campo já auditado no contrato (ENI-54).
