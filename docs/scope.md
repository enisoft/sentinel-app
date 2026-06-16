---
description: Fonte da verdade de arquitetura e contratos do Sentinel
alwaysApply: true
---

# Regra: consultar escopo antes de codar

Antes de gerar, alterar ou refatorar qualquer código deste projeto, consulte
SEMPRE estes documentos como fonte da verdade:

- `sentinel-scope.md` — visão de produto, decisões de arquitetura e estrutura.
- `STATUS_PROJETO.md` — fonte da verdade EXECUTÁVEL: endpoints implementados,
  payloads JSON, campos e status de entrega. Em caso de conflito com o escopo,
  o STATUS_PROJETO.md prevalece para o que já está implementado.

## Regras de uso

1. Não invente endpoints, campos ou contratos. Se não estiver documentado,
   pergunte ou marque como pendente — não assuma.
2. Respeite as decisões de arquitetura já registradas (auth desde a partida,
   UUID no cliente + upsert idempotente, mídia primeiro e sync depois,
   bucket privado, fila com máquina de estados granular).
3. Se uma mudança contrariar o escopo, sinalize explicitamente antes de
   implementar — não altere a direção do projeto silenciosamente.
4. `sentinel-decisoes.md` é histórico do "porquê"; consulte sob demanda quando
   precisar entender a razão de uma decisão, não a cada tarefa.
5. Ao implementar algo novo que altere contratos, lembre de atualizar o
   STATUS_PROJETO.md.