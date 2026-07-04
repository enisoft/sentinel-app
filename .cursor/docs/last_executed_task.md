# Aba Mensagens — inbox + testes

**Tipo:** implementação FE (API + cache local + UI)  
**Data:** 2026-07-04  
**Branch:** working tree

---

## Resumo

Substituída a aba **Tasks** (placeholder) por **Mensagens**: lista estilo ocorrências com status do destinatário, destaque visual para **tarefas**, badge de não lidas, cache Drift offline e detalhe com ações (`read` / `accept` / `reject` / `complete`) conforme tipo e transições da API.

**Detecção de novas mensagens:** polling a cada 60s só com a aba Mensagens aberta; refresh ao entrar na aba, ao abrir a home e ao voltar da captura; pull-to-refresh manual. Cache local exibe a última lista mesmo offline.

---

## Implementação

### 1. Camada de dados

| Peça | Papel |
|------|-------|
| `GET /messages` + `POST .../read\|accept\|complete\|reject` | `ApiClient` |
| `CachedMessages` (Drift schema v7) | cache local |
| `MessageRepository` | fetch, upsert, `unreadCount`, ações |
| `InboxMessage` / `MessageRecipientState` / `MessageType` | modelos e rótulos |

### 2. UI

| Tela | Comportamento |
|------|---------------|
| `MessagesTab` | lista + status à direita; tarefa com fundo índigo e badge |
| `MessageDetailScreen` | abre informe nova → `read` automático; tarefa lida → aceitar/recusar; aceita → concluir |
| `HomeScreen` | aba renomeada; badge `enviada` na bottom nav |

### 3. Transições respeitadas

- **Informe:** enviada → lida  
- **Tarefa:** enviada → lida → aceita → concluída \| recusada  

---

## Arquivos alterados / criados

| Arquivo | Ação |
|---------|------|
| `lib/core/messages/message_type.dart` | **novo** |
| `lib/core/messages/message_recipient_state.dart` | **novo** |
| `lib/domain/models/inbox_message.dart` | **novo** |
| `lib/data/remote/messages_list_response.dart` | **novo** |
| `lib/data/local/tables/cached_messages.dart` | **novo** |
| `lib/data/repositories/message_repository.dart` | **novo** |
| `lib/presentation/home/messages_tab.dart` | **novo** |
| `lib/presentation/home/message_detail_screen.dart` | **novo** |
| `lib/presentation/home/home_screen.dart` | modificado — aba Mensagens + badge |
| `lib/data/remote/api_client.dart` | modificado — endpoints mensagens |
| `lib/data/local/app_database.dart` | modificado — schema v7 |
| `lib/app/di.dart` | modificado — `MessageRepository` |
| `lib/presentation/home/tasks_tab.dart` | removido |
| `test/support/message_test_helpers.dart` | **novo** — fixtures compartilhados |
| `test/core/messages/message_recipient_state_test.dart` | **novo** |
| `test/domain/models/inbox_message_test.dart` | **novo** |
| `test/data/remote/messages_list_response_test.dart` | **novo** |
| `test/data/repositories/message_repository_test.dart` | **novo** |
| `test/presentation/home/messages_tab_test.dart` | **novo** |
| `test/presentation/home/message_detail_screen_test.dart` | **novo** |
| `test/data/remote/api_client_test.dart` | modificado — GET/POST mensagens |
| `test/presentation/home/home_screen_test.dart` | modificado — aba Mensagens + badge |
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | modificado — mock `/messages` |
| `test/presentation/capture/capture_flow_test.dart` | modificado — mock `/messages` |

---

## Testes

```
flutter test
00:09 +199: All tests passed!
```

| Arquivo | Verifica |
|---------|----------|
| `message_recipient_state_test` | `isUnread`, `listLabel`, fallback |
| `inbox_message_test` | `fromJson`, defaults, `copyWith` |
| `messages_list_response_test` | envelope `data` list e `data.items` |
| `message_repository_test` | refresh/ordem, replace cache, unreadCount, read/accept/reject/complete |
| `api_client_test` | GET messages, POST read/accept/complete/reject |
| `messages_tab_test` | vazio, lista+tarefa+status, tap → detalhe |
| `message_detail_screen_test` | auto-read informe, ações tarefa (aceitar → concluir) |
| `home_screen_test` | aba vazia, badge não lidas |
| Suite completa | **199** testes verdes (+22 novos, baseline anterior 177) |

---

## Verificação manual (device G86)

1. Login → aba **Mensagens** carrega lista (ou “Nenhuma mensagem”).
2. Comando envia **informe** → aparece como **Nova**; badge na aba; ao abrir → **Lida**.
3. Comando envia **tarefa** → linha destacada (índigo); abrir → aceitar/recusar; aceita → concluir.
4. Modo avião com cache → lista anterior visível; pull-to-refresh mostra erro sem apagar cache.

---

## AUDITORIA

Não exigida — feature read-mostly inbound; não altera sync de ocorrências nem auth.

---

*Implementação aba Mensagens + suite de testes concluída.*
