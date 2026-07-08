# ENI-97 — reported_by na captura + sync + filtro por dono

**Tipo:** feature / isolamento multi-operador no device  
**Data:** 2026-07-08  
**Branch:** working tree

---

## Objetivo

Carimbar o operador dono (`reported_by`) na captura local, enviar no payload de sync (backend respeita na 1ª gravação, imutável depois) e filtrar a lista para cada operador ver só as suas ocorrências.

---

## Implementação

| # | Item | Estado |
|---|------|--------|
| 1 | Drift: coluna `reported_by` (nullable) + migration schema v8 | **Feito** |
| 2 | Captura: `reported_by = uid` da sessão no `createOccurrence` | **Feito** |
| 3 | Serializer: `reported_by` no JSON de sync quando presente | **Feito** |
| 4 | Lista (`occurrences_tab`): `listForOperator(uid)` em vez de `listAll()` | **Feito** |
| 5 | Legadas sem `reported_by`: órfãs — não aparecem na lista de ninguém | **Feito** (aviso UI = parte 2) |

### Decisão — ocorrências legadas (pré ENI-97)

- `reported_by = null` → **órfã**
- **Não** atribuir ao operador logado na migration (risco de dono errado)
- Permanecem no Drift; **não** aparecem na lista de nenhum operador
- `OccurrenceRepository.countOrphanOccurrences()` disponível para aviso futuro
- Sync: serializer omite `reported_by` quando null (backend pode derivar do token nesse caso legado)

### Arquivos alterados / criados

| Arquivo | Ação |
|---------|------|
| `lib/data/local/tables/occurrences.dart` | coluna `reportedBy` |
| `lib/data/local/app_database.dart` | schema v8 + migration |
| `lib/domain/gateways/auth_gateway.dart` | `currentUserId` |
| `lib/data/gateways/supabase_auth_gateway.dart` | `currentUser?.id` |
| `lib/data/fakes/fake_auth_gateway.dart` | `userId` para testes |
| `lib/data/repositories/occurrence_repository.dart` | `reportedBy`, `listForOperator`, `countOrphanOccurrences` |
| `lib/data/services/capture_occurrence_service.dart` | carimbo na captura |
| `lib/data/sync/sync_payload_serializer.dart` | `reported_by` no payload |
| `lib/presentation/home/occurrences_tab.dart` | filtro por dono |
| `lib/app/di.dart` | wiring CaptureOccurrenceService |
| `.cursor/rules/sentinel-app.md` | regra atualizada (reported_by no payload) |
| `test/data/repositories/occurrence_reported_by_test.dart` | **novo** |
| `test/presentation/home/home_screen_test.dart` | isolamento ENI-97 |
| `test/data/sync/sync_payload_serializer_test.dart` | expect `reported_by` |
| `test/data/gateways/sync_gateway_http_test.dart` | expect `reported_by` |
| `test/data/services/capture_occurrence_service_test.dart` | assert stamp |
| `test/presentation/capture/capture_flow_test.dart` | FakeAuthGateway no DI |
| `.cursor/docs/audit_2026-07-08_eni-97.md` | **novo** |

---

## Testes

```
flutter test
00:08 +215: All tests passed!
```

**215/215 verdes** (+6 novos).

Cobertura ENI-97:
- captura grava `reported_by = uid` logado
- serializer inclui `reported_by` no payload
- `listForOperator` mostra só do uid; outro uid e órfãs ocultas
- widget test: lista esconde ocorrências de outro operador

---

## Verificação manual (pendente — G86)

1. Operador A captura 2 → aparecem pra A.
2. Logout. Login B → B **não** vê as de A; captura as suas.
3. B sincroniza → Postgres: ocorrências de A (se na fila) mantêm `reported_by=A`.
4. Login A de volta → vê as dele.

---

## Auditoria

Ver `.cursor/docs/audit_2026-07-08_eni-97.md`.

| Verificação | Resultado |
|-------------|-----------|
| Lista isola por uid | ✅ |
| Captura carimba dono certo | ✅ |
| `reported_by` no payload | ✅ |
| Outro uid não vaza na lista | ✅ |
| Legadas sem atribuir dono errado | ✅ |

---

# Higiene pré-deploy — app

**Tipo:** higiene / verificação pré-deploy  
**Data:** 2026-07-08  
**Branch:** working tree

---

## 1. Segredos e dumps no git

| Verificação | Resultado |
|-------------|-----------|
| `git ls-files \| grep -iE '\.(db\|sqlite\|sqlite3)$'` | **`sentinel-device.db`** estava rastreado (69 KB, dump local de dispositivo) |
| Ação | `git rm --cached sentinel-device.db` + padrões `*.db`, `*.sqlite`, `*.sqlite3` em `.gitignore` |
| `.env` rastreado? | **Não** — só `.env.example` |
| Keystore no gitignore? | **Sim** — `android/.gitignore:13-14` (`**/*.keystore`, `**/*.jks`) |

**Arquivo removido do git:** `sentinel-device.db` (permanece localmente ignorado).

---

## 2. Suíte verde e análise estática

### `flutter test`

```
00:08 +215: All tests passed!
```

**215/215 verdes** — conforme esperado (209 anteriores + 6 ENI-97).

### `flutter analyze` (warnings relevantes; info/deprecated omitidos)

| Arquivo | Issue |
|---------|-------|
| `lib/app/di.dart:97` | `invalid_use_of_visible_for_testing_member` — `setMockInitialValues` fora de test |
| `lib/data/fakes/fake_sync_gateway.dart:44` | `unnecessary_non_null_assertion` |
| `test/data/services/occurrence_sync_foreground_notification_test.dart:6` | import não usado |
| `test/data/services/occurrence_sync_foreground_runner_test.dart:6` | import não usado |
| `test/presentation/capture/occurrence_draft_resume_test.dart:27` | variável local não usada |
| `test/presentation/home/message_detail_screen_test.dart:8` | import não usado |
| `tools/query_sentinel_db.dart:1` | import `dart:io` não usado |

Total: 29 issues (6 warnings em produção/fakes, 4 em testes, 1 em tools; restante info/deprecated em widgets).

---

## 3. Operador inativo (403) — backend OK; app pendente

**Atualização 2026-07-08:** backend ENI-85 corrigido e testado.

### Teste backend (`OperatorInactiveApiAuthTest`)

```
php artisan test tests/Feature/Api/V1/OperatorInactiveApiAuthTest.php

PASS  Tests\Feature\Api\V1\OperatorInactiveApiAuthTest
  ✓ active operator can access me
  ✓ inactive operator gets 403 on me
  ✓ inactive operator gets 403 on occurrence sync
  ✓ inactive operator gets 403 on messages
  ✓ inactive operator gets 403 on catalog zones
  ✓ inactive operator gets 403 on check in sync
  ✓ operator deactivated mid session gets 403 on next request

Tests: 7 passed (17 assertions)
```

Contrato confirmado: HTTP **403** + `message: "Conta de operador inativa."` em `/me`, sync, messages e catalog. Middleware: `sentinel-backend/app/Http/Middleware/AuthenticateSupabaseJwt.php:52-53`.

| Aspecto | Estado atual |
|---------|--------------|
| Backend API | **OK** — `is_active=false` → 403 com mensagem clara (ENI-85) |
| `GET /me` | **Não** expõe `is_active` (por design; detecção via 403) |
| App | **Pendente** — `shouldSignOutForUnauthorized` só reage a **401**; **403** cai no ramo genérico de erro em `AppBootstrapScreen` (mensagem + “Tentar novamente”, **sem logout**) |
| Sync | `occurrence_sync_service.dart` só desloga em 401 via `shouldSignOutForUnauthorized` |

**O que falta no app (contrato backend já pronto):**

1. `ApiException.isForbidden` (403); `AuthMessages.operatorInactive` (“Conta de operador inativa.”).
2. Método em `AuthGateway` tipo `shouldSignOutForForbidden` (logout imediato online, sem tratar como rede, sem refresh).
3. Tratar 403 em `AppBootstrapScreen`, `OccurrenceSyncService` e demais chamadas API autenticadas — mensagem dedicada + `signOut(loginNotice: ...)`.
4. Testes widget/unit para 403 em `/me` e sync (espelhando padrão dos testes 401 existentes).

---

## Veredito pré-deploy (app)

| Item | Status |
|------|--------|
| Dumps `.db` no repo | **Corrigido** (removido + gitignore) |
| `.env` / keystore | **OK** |
| `flutter test` | **215/215 verdes** |
| `flutter analyze` | Warnings menores — não bloqueante |
| ENI-97 reported_by | **Feito** — smoke manual G86 pendente |
| Operador inativo 403 | **Backend OK** (7/7 ENI-85) — **app pendente** (tratar 403 + logout) |

---

# ENI-84 — Sessão persiste offline; captura sem rede

**Tipo:** correção auth/sessão (offline-first)  
**Data:** 2026-07-05  
**Branch:** working tree

---

## Problema

Operador logado offline (JWT expira, refresh Supabase falha) era derrubado para login e não conseguia capturar.

## Causa

- `sessionStream` do Supabase emitia não-autenticado após refresh falho → `AuthGate` ia para `LoginScreen`.
- `accessToken == null` → `ApiClient` lançava 401 local → `signOut` com "sessão expirada".

## Correção

| Peça | Mudança |
|------|---------|
| `AuthGateway` | `appAccessStream`, `canAccessApp`, `hasPersistedSession`, `tryRefreshSessionSilently`, `shouldSignOutForUnauthorized` |
| `SupabaseAuthGateway` | Mantém acesso se Keystore (`sb-session`) intacto; refresh silencioso; signOut só com 401 online após refresh falho |
| `AuthGate` | Usa `appAccessStream` em vez de `sessionStream` |
| `ApiClient` | Token ausente + sessão persistida → `ApiException.network` (não 401) |
| `TusMediaUploader` | Token ausente → `MediaUploadException` rede (não 401) |
| `AppBootstrapScreen` | Refresh no startup; signOut condicional; fallback perfil cache offline |
| `OccurrenceSyncService` | 401 só desloga online após refresh falho; offline enfileira com `hadNetworkFailure` |
| `NetworkReachability` | `DnsNetworkReachability` + `FakeNetworkReachability` para testes |

## Arquivos alterados / criados

| Arquivo | Ação |
|---------|------|
| `lib/domain/gateways/auth_gateway.dart` | modificado — contrato ENI-84 |
| `lib/data/gateways/supabase_auth_gateway.dart` | modificado — appAccess offline |
| `lib/core/network/network_reachability.dart` | **novo** |
| `lib/data/fakes/fake_network_reachability.dart` | **novo** |
| `lib/data/fakes/fake_auth_gateway.dart` | modificado — simula offline |
| `lib/presentation/auth/auth_gate.dart` | modificado — appAccessStream |
| `lib/presentation/bootstrap/app_bootstrap_screen.dart` | modificado — refresh + signOut condicional |
| `lib/data/remote/api_client.dart` | modificado — token offline = rede |
| `lib/data/remote/tus_media_uploader.dart` | modificado — upload adiado offline |
| `lib/data/services/occurrence_sync_service.dart` | modificado — 401 condicional |
| `lib/app/di.dart` | modificado — Keystore + NetworkReachability |
| `test/presentation/auth/auth_gate_offline_test.dart` | **novo** |
| `test/data/remote/api_client_test.dart` | modificado |
| `test/data/services/occurrence_sync_service_test.dart` | modificado |
| `test/data/services/capture_occurrence_service_test.dart` | modificado |
| `test/presentation/bootstrap/app_bootstrap_screen_test.dart` | modificado |
| `.cursor/docs/audit_2026-07-05_eni-84.md` | **novo** |

## Testes

```
flutter test
00:08 +209: All tests passed!
```

Cobertura ENI-84:
- sessionStream null + Keystore → permanece no app
- captura com `accessToken` null
- 401 online → desloga
- 401 offline sync → não desloga
- refresh silencioso ao reconectar

## Verificação manual (pendente — G86)

1. Logar no Wi-Fi → modo avião → reabrir app → **não** cai pro login; captura OK; fila cresce.
2. Voltar rede → sync sobe; segue logado sem novo login.

## Auditoria

Ver `.cursor/docs/audit_2026-07-05_eni-84.md`.

---

## Auditoria board vs código (pré-deploy)

**Data:** 2026-07-08  
**Modo:** read-only — nenhum código alterado  
**Escopo:** itens 9–16 do board Linear (app + higiene) vs código em `sentinel-app` e `sentinel-backend`

### Tabela por item

| # | Item board | Veredito | Evidência (arquivo:linha) | Testes |
|---|------------|----------|---------------------------|--------|
| **9** | Captura real: foto+GPS+hash, vídeo 720p+wakelock+limite 5min, multi-mídia, pega-tudo | **EXISTE e coerente** | Foto+GPS+hash: `lib/data/services/capture_occurrence_service.dart:34-56` (`GeolocatorLocationSource` `lib/data/device/geolocator_location_source.dart:16-42`, `CryptoHashService` `lib/data/device/crypto_hash_service.dart:10-17`). Vídeo 720p padrão: `lib/core/capture/capture_resolution.dart:4-5` + `lib/data/settings/capture_quality_settings.dart:5`. Wakelock: `lib/presentation/capture/in_app_capture_controls.dart:48-61,104,116,151`. Limite 5min: `lib/core/capture/video_recording_policy.dart:2-6` + timer `in_app_capture_controls.dart:106-114`. Multi-mídia: `capture_occurrence_service.dart:93-112`, UI `lib/presentation/capture/capture_home_screen.dart:81-93`. Pega-tudo (ENI-60): `capture_home_screen.dart:17-19` — preview contínuo, form só em "Concluir". Produção usa `DeviceCameraSource` + GPS/hash reais: `lib/app/di.dart:242-249`. | `test/data/services/capture_occurrence_service_test.dart`, `test/core/capture/video_recording_policy_test.dart`, `test/presentation/capture/capture_flow_test.dart` (pega-tudo, multi-mídia, vídeo), `test/data/device/crypto_hash_service_test.dart` |
| **10** | Zona no form (padrão+editável). `content_hash` enviado no sync | **EXISTE e coerente** | Zona: dropdown `lib/presentation/capture/occurrence_draft_form_screen.dart:87-97,220-237` (pré-seleciona `profile.defaultZoneId`, editável salvo em `zonaId`). Persistência: `occurrence_repository.dart:128-139`. Sync `zona_id`: `lib/data/sync/sync_payload_serializer.dart:25`. `content_hash`: `sync_payload_serializer.dart:55`, coluna Drift `lib/data/local/tables/occurrence_media.dart:17`. | `test/presentation/capture/occurrence_draft_form_zone_test.dart`, `test/data/sync/sync_payload_serializer_test.dart:136-184,190-210` |
| **11** | Sync manual-first + badge. Offline não desloga; sessão expirada offline permite captura (ENI-84) | **EXISTE e coerente** | Manual-first: sync só via botão `lib/presentation/home/occurrences_tab.dart:79-80,133` (`pending_sync_badge`); sem auto-sync pós-confirmação. Offline auth: `lib/data/gateways/supabase_auth_gateway.dart:60-90`, `lib/presentation/auth/auth_gate.dart` (appAccessStream), `lib/data/remote/api_client.dart` (token offline → rede), `lib/data/services/occurrence_sync_service.dart` (401 condicional). Captura sem token: `capture_occurrence_service.dart:27-30`. | `test/presentation/capture/capture_flow_test.dart:337-366` (sem auto-sync), `:380-403` (manual sync), `test/presentation/auth/auth_gate_offline_test.dart`, `test/data/services/occurrence_sync_service_test.dart:239`, `test/data/services/capture_occurrence_service_test.dart:55`, `test/data/remote/api_client_test.dart:117` |
| **12** | Comunicação: inbox mensagens, estados, POST read/accept/complete/reject | **EXISTE e coerente** | Inbox: `lib/presentation/home/messages_tab.dart:15-44`. Estados: `lib/core/messages/message_recipient_state.dart:3-30`. POST: `lib/data/remote/api_client.dart:57-67`. Repo: `lib/data/repositories/message_repository.dart:54-72`. Detalhe + ações tarefa: `lib/presentation/home/message_detail_screen.dart:47-49,178-214` (read automático ao abrir; accept/reject em `lida`; complete em `aceita`). | `test/domain/models/inbox_message_test.dart`, `test/presentation/home/messages_tab_test.dart`, `test/presentation/home/message_detail_screen_test.dart`, `test/core/messages/message_recipient_state_test.dart` |
| **13** | Retomar rascunho + lista navegável; rascunho fora do sync | **EXISTE e coerente** | Retomar form: `occurrence_draft_form_screen.dart:70-87` repopula campos/mídia. Lista navegável: `lib/presentation/home/occurrences_tab.dart:73-105,84-92` (tap draft → form). Rascunho fora da fila: `lib/data/repositories/sync_queue_repository.dart:62-68,83-91` (só `status=pending`); rótulo `occurrences_tab.dart:334-337` "Não confirmada". | `test/presentation/capture/occurrence_draft_resume_test.dart`, `test/presentation/home/home_screen_test.dart:178-285,261`, `test/data/repositories/repositories_test.dart:205-228` |
| **14** | Migrations aplicam limpo do zero (`migrate:fresh` + seed)? Suíte backend e app verdes? | **PARCIAL** | `php artisan migrate:fresh --seed` no backend: **OK** (25 migrations + ZonaSeeder + MessageSeeder, 2026-07-08). App `flutter test`: **215/215 verdes**. Backend `php artisan test`: **198/210** — **12 falhas** em testes Panel (WallMap, WallTotais, ZonaCascadeChildren): schema PostgreSQL `testing` sem tabelas/colunas (`roles`, `municipalities.deleted_at`, `zonas.parent_zona_id`). `migrate:fresh` rodou no schema `public` (`.env`); PHPUnit usa `DB_SCHEMA=testing` (`phpunit.xml:32`). | Execução local 2026-07-08 |
| **15** | `.env` / segredo / keystore commitado? `sentinel-device.db` ou dumps no repo? | **CORRIGIDO** (2026-07-08) | `.env` **não** rastreado (só `.env.example`). Keystore: `android/.gitignore:13-14`. `sentinel-device.db` **removido** do git (`git rm --cached`) + `*.db`/`*.sqlite*` no `.gitignore`. | `git ls-files` + higiene pré-deploy |
| **16** | Testes totais: backend (~210) e app (~154+) | **PARCIAL** | App: **215** testes, todos passando (esperado ~154+ ✅). Backend: **210** testes contados (esperado ~210 ✅), mas **12 erros** — suíte **não verde** (ver item 14). | `flutter test` + `php artisan test` 2026-07-08 |

### Divergências priorizadas (corrigir antes do deploy)

| Prioridade | Divergência | Impacto | Ação sugerida |
|------------|-------------|---------|---------------|
| **P0 — bloqueante** | Backend: 12/210 testes falham (schema `testing` desatualizado vs migrations) | CI/deploy não pode considerar backend verde; risco de regressão em Wall Map/Totais/Zona cascade | Garantir `RefreshDatabase` + migrations no schema `testing` (porta 55322) antes de `php artisan test`; validar pipeline com mesmo `DB_SCHEMA` do `phpunit.xml` |
| **P1 — higiene** | ~~`sentinel-device.db` versionado no repositório (69 KB)~~ | ~~Dump local de dispositivo no histórico git~~ | **Resolvido 2026-07-08:** `git rm --cached` + `.gitignore`. Histórico git ainda contém o blob — considerar `git filter-repo` se dados sensíveis. |
| **P1 — app** | Operador inativo: backend retorna 403, app não desloga | Operador desativado vê erro genérico e permanece “logado” no app | Implementar tratamento 403 no app (ver secção 3) — contrato backend pronto |
| **P2 — validação manual** | ENI-84 + ENI-97: verificação manual G86 pendente | Comportamento offline e multi-operador só cobertos por testes unit/widget | Executar checklists antes de produção |
| **P3 — cobertura menor** | Wakelock de gravação sem teste dedicado | Código existe (`in_app_capture_controls.dart`) mas sem assert automatizado | Aceitável para deploy se G86 manual OK; opcional: widget test com mock de `WakelockPlus` |
| **P3 — nuance técnica** | 720p = `ResolutionPreset.medium` (~720p), não garantia pixel-exact | Alinhado ao contrato histórico e settings HD opcional | Documentado; sem ação obrigatória |

### Veredito pré-deploy

**App (itens 9–13):** código alinhado ao board — captura, zona, sync manual-first, mensagens e rascunhos **conferem** com testes verdes (215). ENI-97 adiciona isolamento por operador no device.

**Higiene / backend (itens 14–16):** P1 higiene app **resolvido** (`sentinel-device.db`). Backend ENI-85 **OK** (`OperatorInactiveApiAuthTest` 7/7). Backend ainda com P0 (suíte geral vermelha — 12 falhas Panel). **App:** tratamento 403-inativo ainda pendente (P1). Recomenda-se completar P2 (smoke manual ENI-84 + ENI-97 em device real).

---

## INVESTIGACAO — autoria na sync + escopo por operador no device

**Data:** 2026-07-08  
**Modo:** read-only (nenhum codigo alterado)  
**Resolvido por:** ENI-97 (2026-07-08)

### Respostas objetivas (itens 1-5) — estado **antes** do fix

1. **A ocorrencia local tem dono (uid) salvo no Drift?**  
   **Nao.** A tabela `occurrences` nao possui coluna `reported_by`, `operator_id`, `user_id` ou equivalente; so metadados da ocorrencia/sync (`id`, `title`, `status`, `syncState`, timestamps etc.).  
   **Evidencia:** `lib/data/local/tables/occurrences.dart:5-33`.

2. **No momento da captura/criacao, o app salva uid do operador junto da ocorrencia?**  
   **Nao.** A criacao local (`createOccurrence`) recebe campos da ocorrencia, mas nao recebe nem persiste uid do operador.  
   **Evidencia:** `lib/data/repositories/occurrence_repository.dart:20-64`, `lib/data/services/capture_occurrence_service.dart:38-47`.

3. **A sincronizacao preserva autoria A->A quando B sincroniza no mesmo device?**  
   **No app, nao ha como preservar autoria original por payload local.** O serializer de sync nao envia `reported_by`/`user_id`; o backend deriva autoria do JWT ativo. Logo, se B sincronizar um item local antigo de A, a autoria enviada pelo app fica vinculada ao token de B (a menos de tratamento especial no backend fora do payload).  
   **Evidencia app:** `lib/data/sync/sync_payload_serializer.dart:21-43`; regra do projeto `reported_by/user_id` nunca no payload em `.cursor/rules/sentinel-app.md:22-23`.  
   **Contrato documentado:** `docs/sentinel-scope.md:85`, `docs/sentinel-scope.md:182`.

4. **A lista de ocorrencias (`occurrences_tab`) filtra por operador logado?**  
   **Nao.** A aba carrega `listAll()` e renderiza tudo que estiver no Drift local, sem filtro por uid/dono.  
   **Evidencia:** `lib/presentation/home/occurrences_tab.dart:73-77`; `lib/data/repositories/occurrence_repository.dart:104-109`.

5. **Ao logar com uid diferente do ultimo, algo e limpo no local?**  
   **Hoje, nao foi encontrada limpeza de ocorrencias locais na troca de sessao.** O logout chama apenas `auth.signOut()`; nao ha rotina de purge em `occurrences`. O bootstrap sincroniza perfil/catalogo, mas nao limpa tabela de ocorrencias.  
   **Evidencia:** `lib/presentation/home/home_screen.dart:63-65`; `lib/data/gateways/supabase_auth_gateway.dart:103-110`; `lib/data/services/bootstrap_service.dart:24-50`; ausencia de delete em `occurrences` (repositorio apenas insere/atualiza e remove midia): `lib/data/repositories/occurrence_repository.dart:61`, `lib/data/repositories/occurrence_repository.dart:146-148`, `lib/data/repositories/occurrence_repository.dart:169-170`.

### Conclusoes para decisao de fix

- **(a) autoria e preservada na sync?**  
  **Nao, pelo app atual.** O app nao envia autoria historica local e o contrato assume autoria derivada do token atual.

- **(b) o local tem dono por uid?**  
  **Nao.** Nao existe coluna de dono por operador nas ocorrencias locais.

- **(c) a lista filtra por dono?**  
  **Nao.** A lista mostra todas as ocorrencias do Drift (`listAll`), sem escopo por operador.

### Estado pós ENI-97

| Pergunta | Resposta |
|----------|----------|
| (a) autoria na sync | **Sim** — `reported_by` carimbado localmente e enviado no payload |
| (b) dono no Drift | **Sim** — coluna `reported_by` |
| (c) lista filtra | **Sim** — `listForOperator(uid)` |
