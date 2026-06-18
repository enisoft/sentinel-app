# Referências do ecossistema Sentinel

Mapa da documentação do `sentinel-app`: o que é nativo deste repo, o que é cópia
do backend, e qual fonte prevalece em caso de divergência.

---

## Hierarquia de fontes

| Pergunta | Fonte de verdade |
|----------|------------------|
| O que o **app Flutter implementa hoje**? | Código em `lib/` + `test/` → [`ARQUITETURA.md`](ARQUITETURA.md) |
| **Contrato de API** (rotas, payloads, ordem de build)? | `sentinel-backend` → cópias locais abaixo |
| **Estado do backend** (rotas, testes PHPUnit, detalhes de sync)? | `sentinel-backend` → [`STATUS_PROJETO.md`](STATUS_PROJETO.md) |
| **Visão de produto** (o que o sistema é/será)? | `sentinel-backend` → [`sentinel-scope.md`](sentinel-scope.md) |
| **Por quê** (decisões históricas)? | `sentinel-backend` → [`sentinel-decisoes.md`](sentinel-decisoes.md) |

### Regra de conflito

- **Implementação do app:** se `ARQUITETURA.md` divergir do código, **o código vence**.
- **Contrato API / backend:** se qualquer doc local divergir do `sentinel-backend`, **o backend vence** — atualize a cópia manual, não invente no app repo.
- **App vs contrato:** se o código consumir algo diferente do contrato em `sentinel-api-app.md`, trate como bug de implementação ou contrato desatualizado no backend (corrigir no repo certo).

---

## Documentos nativos do sentinel-app

Editar **neste repositório**:

| Arquivo | Conteúdo |
|---------|----------|
| [`README.md`](../README.md) | Onboarding: `.env`, comandos, resumo E10 |
| [`ARQUITETURA.md`](ARQUITETURA.md) | Arquitetura e estado pós-E10 derivados de `lib/` + `test/` |

---

## Cópias manuais do sentinel-backend

Os arquivos abaixo são **colados manualmente** do `sentinel-backend`. **Não editar**
no `sentinel-app` — alterações devem ser feitas no backend e a cópia re-sincronizada.

| Cópia local | Origem no backend |
|-------------|-------------------|
| [`sentinel-api-app.md`](sentinel-api-app.md) | `sentinel-backend/docs/sentinel-api-app.md` |
| [`STATUS_PROJETO.md`](STATUS_PROJETO.md) | `sentinel-backend/docs/STATUS_PROJETO.md` |

### Como atualizar

1. Editar o documento no `sentinel-backend`.
2. Copiar o conteúdo integral para o caminho correspondente em `sentinel-app/docs/`.
3. Commitar nos dois repos (ou só no app, se a mudança foi só no backend e a cópia acompanha).

---

## Documentos de produto (consulta)

Também existem localmente; em divergência, o `sentinel-backend` é autoridade:

| Cópia local | Origem no backend |
|-------------|-------------------|
| [`sentinel-scope.md`](sentinel-scope.md) | `sentinel-backend/sentinel-scope.md` |
| [`sentinel-decisoes.md`](sentinel-decisoes.md) | `sentinel-backend/.cursor/rules/sentinel-decisoes.md` |

---

## Uso no desenvolvimento

1. **Nova integração de rede no app** → ler `sentinel-api-app.md` (cópia do backend).
2. **Payload ou comportamento HTTP em dúvida** → `STATUS_PROJETO.md` + código em `sentinel-backend`.
3. **O que já está no Flutter** → `ARQUITETURA.md` + código.
4. **Regras do agente** → [`.cursor/rules/sentinel-app.md`](../.cursor/rules/sentinel-app.md).
