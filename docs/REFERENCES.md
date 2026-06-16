# Referências do ecossistema Sentinel

Documentos de **fonte da verdade** para o `sentinel-app`. Não duplicar o conteúdo
deles neste repositório — consultar os originais ou a cópia manual quando existir.

Em caso de **divergência**, o repositório **sentinel-backend** é a autoridade.

## Documentos no sentinel-backend

| Documento | Caminho (relativo a este repo) | Conteúdo |
|-----------|----------------------------------|----------|
| `sentinel-scope.md` | [`../sentinel-backend/sentinel-scope.md`](../sentinel-backend/sentinel-scope.md) | Arquitetura, UX capture-first, fila offline, máquina de estados, TUS |
| `sentinel-decisoes.md` | [`../sentinel-backend/.cursor/rules/sentinel-decisoes.md`](../sentinel-backend/.cursor/rules/sentinel-decisoes.md) | Histórico de decisões (consultar sob demanda) |
| `sentinel-api-app.md` | **Referência externa — ainda não copiada para este repo** | Superfície de API que o app consome, em ordem de build |

### `sentinel-api-app.md` — status

Este arquivo **ainda não existe** no `sentinel-backend` (apenas referenciado no escopo).
**Não inventar** campos, rotas ou formatos com base em suposições.

Quando o documento estiver disponível, **colar manualmente** em `docs/` deste
repositório (`sentinel-app/docs/sentinel-api-app.md`).

Até lá, o contrato implementado no backend para sync de ocorrências está em
[`../sentinel-backend/STATUS_PROJETO.md`](../sentinel-backend/STATUS_PROJETO.md)
(seção `POST /api/v1/occurrences/sync`).

## Uso no desenvolvimento

1. Antes de implementar integração de rede, ler o contrato em `sentinel-api-app.md`
   (quando copiado) ou `STATUS_PROJETO.md` (interim).
2. Regras do agente: [`.cursor/rules/sentinel-app.md`](../.cursor/rules/sentinel-app.md).
