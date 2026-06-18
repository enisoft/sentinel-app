# Sentinel App — Arquitetura e estado atual (pós-E10)

Documento derivado do **código em `lib/` e testes em `test/`**. Em caso de divergência
com outros docs, **o código vence**.

Última revisão: 2026-06-18.

---

## Épicos E10 — o que está pronto

| Sub-épico | Escopo | Estado no código |
|-----------|--------|------------------|
| **E10.0** | Login Supabase, `GET /me`, catálogo offline (delta → Drift) | ✅ Implementado e testado |
| **E10.1** | `SyncGatewayHttp` — `POST /occurrences/sync` via `ApiClient` | ✅ Implementado e testado |
| **E10.2** | Upload TUS resumable (`tus_client_dart`) atrás de `MediaUploader` | ✅ Implementado e testado |
| **E10.3a** | Sync em background (Foreground Service + UIDT) | ⏳ Pendente — não há FGS, WorkManager nem listener de conectividade |
| **E10.3b** | Política Wi-Fi para vídeo | ⏳ Pendente — não há restrição de rede por tipo de mídia |
| **E9 fase 2** | Câmera real no device | ⏳ Pendente — produção usa `FakeDeviceCameraSource` |

Validação em device físico (G56): ciclo offline-first com TUS + sync JSON confirmado
(ver `.cursor/docs/last_executed_task.md`, ENI-31 passo 6).

---

## Camadas e DI

Estrutura **layer-first**:

```
lib/
  app/           # bootstrap, get_it (configureDependencies)
  core/          # config, sync state machine, mensagens puras
  domain/        # contratos (gateways, models, services)
  data/          # drift, repositórios, remote API, TUS, auth
  presentation/  # telas (auth, bootstrap, captura)
```

**DI:** [`get_it`](https://pub.dev/packages/get_it) em `lib/app/di.dart`.

- **Produção:** `configureDependencies()` — Supabase + secure storage, `TusMediaUploader`,
  `SyncGatewayHttp`, `FakeDeviceCameraSource`.
- **Testes:** `configureDependenciesForTesting()` — banco em memória, `FakeCameraSource`
  por padrão, gateways injetáveis.

---

## Segurança de sessão (ENI-33)

O JWT da sessão Supabase **não** fica em `SharedPreferences`.

| Componente | Função |
|------------|--------|
| `FlutterSecureKeyValueStore` | Wrapper de `flutter_secure_storage` (Keystore no Android) |
| `SecureSupabaseLocalStorage` | `LocalStorage` do SDK Supabase — persiste em secure storage |
| `SecureGotrueAsyncStorage` | PKCE / fluxo GoTrue também em secure storage |
| `supabaseSecureSessionKey` | Chave estável: `sb-session` |

**Migração legada:** na primeira inicialização, `SecureSupabaseLocalStorage` lê a sessão
antiga em SharedPreferences (`sb-<host>-auth-token`), copia para o Keystore e remove a
chave legada. Coberto por `test/data/auth/secure_supabase_local_storage_test.dart`.

`signOut` limpa a sessão no secure storage via SDK Supabase.

---

## Comportamento offline-first

### Bootstrap — rede ≠ 401 (ENI-38)

Fluxo: `AuthGate` → `AppBootstrapScreen` → `BootstrapService.run()`.

| Cenário `GET /me` | Comportamento |
|-------------------|---------------|
| Rede OK | `OperatorProfileRepository.fetchAndCache()` — perfil atualizado no Drift |
| Falha de rede + perfil em cache | `profileLoaded: true` — operador permanece logado |
| Falha de rede + sem cache (primeiro acesso) | Mensagem dedicada, **sem** `signOut` |
| HTTP `401` real | `ApiException.isUnauthorized` → `signOut` |

`ApiClient` encapsula `SocketException`, `ClientException` e timeout (`408`) em
`ApiException.network()` com `isNetworkError: true` — nunca tratados como sessão inválida.

Catálogo: falha de sync não bloqueia captura; banner de aviso na home se `catalogSynced == false`.

### Fila de ocorrências

Estados (`SyncState`):

```
local_saved → media_uploading → media_done → json_syncing → synced
                                                      ↘ failed
```

1. Captura offline grava ocorrência + mídia local no Drift (`local_saved`).
2. Ao sincronizar: upload TUS de cada mídia → `POST /occurrences/sync` → `synced`.
3. `processPending()` é chamado em:
   - **Cold start** — `AppBootstrapScreen` (após bootstrap de perfil/catálogo).
   - **Confirmação de rascunho** — `OccurrenceDraftFormScreen` (fire-and-forget).

**Limitação atual (não é bug):** não há listener de conectividade. Religar Wi-Fi com o app
em foreground **não** dispara sync até cold start ou nova confirmação de rascunho.

**Melhoria futura (ENI-39):** sync imediato ao reconectar.

---

## Upload TUS e sync HTTP (E10.1 + E10.2)

### Fronteiras

```
OccurrenceSyncService
    → SyncGateway (interface)
        → uploadOccurrenceMedia → MediaUploader (interface)
            → TusMediaUploader  ← único import de tus_client_dart
        → syncOccurrences → ApiClient.postOccurrencesSync
```

`SyncGatewayHttp` delega mídia ao `MediaUploader` e JSON ao `ApiClient`.
`syncCheckIns` lança `UnimplementedError` (fora de escopo E10.1).

### Ordenação mídia → JSON

`OccurrenceSyncService.processPending()` para cada ocorrência pendente:

1. `_advanceMedia` — sobe mídias com `remote_path` null via TUS.
2. `_advanceToJsonSync` — transição `media_done` → `json_syncing`.
3. `_gateway.syncOccurrences` — POST JSON; confirma por `data.ids`.

Falha de mídia não avança para JSON. `401` em upload ou sync chama `signOut`.

### Path canônico no Storage

Definido em `OccurrenceRepository.canonicalStoragePath`:

```
occurrences/{occurrence_id}/{media_id}.{ext}
```

Extensão derivada do MIME (`image/jpeg` → `jpg`, `video/mp4` → `mp4`, etc.).

Bucket: `sentinel-media`. Endpoint TUS: `{SUPABASE_URL}/storage/v1/upload/resumable`.
Chunks de 6 MiB, retries exponenciais. Após upload OK, `remote_path` é gravado no Drift.

---

## Configuração `.env`

Variáveis obrigatórias (carregadas por `AppConfig.load()` via `flutter_dotenv`):

| Variável | Uso |
|----------|-----|
| `SUPABASE_URL` | Auth Supabase + endpoint TUS Storage |
| `SUPABASE_ANON_KEY` | Chave anon do projeto local |
| `API_BASE_URL` | Base da API Laravel (`/api/v1`, sem barra final) |

**Emulador Android:** `10.0.2.2` aponta para localhost do host.

**Device físico:** substituir por IP LAN da máquina (ex.: `http://192.168.x.x:54321`).

Template: `.env.example`. O `.env` local está em `pubspec.yaml` → `assets` para bundle
em debug; não commitar secrets.

Obter `SUPABASE_ANON_KEY`:

```bash
cd sentinel-backend && npx supabase status -o env
```

Backend local típico: `php artisan serve` em `:8000`.

---

## Câmera e localização (ENI-36)

| Classe | Uso | Comportamento |
|--------|-----|---------------|
| `FakeDeviceCameraSource` | **Produção** (`di.dart` → `_registerCaptureFakes`) | Grava JPEG mínimo válido em disco (`getTemporaryDirectory`) — arquivo real para TUS |
| `FakeCameraSource` | **Testes** (`configureDependenciesForTesting`) | Retorno em memória, path configurável, sem I/O |

`FakeLocationSource` e `FakeHashService` completam a captura simulada em produção.

**Câmera real (E9 fase 2):** não implementada. Substituir `CameraSource` na DI quando
existir implementação de hardware.

---

## Testes

```bash
flutter test
```

Suíte cobre: secure storage/migração, `ApiClient` (rede vs 401), bootstrap offline,
`OccurrenceSyncService`, `SyncGatewayHttp`, TUS path canônico, fluxo de captura,
`FakeDeviceCameraSource`.

Contrato de API consumido: [`docs/sentinel-api-app.md`](sentinel-api-app.md).

Referências do ecossistema: [`docs/REFERENCES.md`](REFERENCES.md).

---

## Fora de escopo (confirmado no código)

- Sync de check-ins HTTP (`syncCheckIns` não implementado)
- Inbox de tasks
- Foreground Service / UIDT (E10.3a)
- Política Wi-Fi por tipo de mídia (E10.3b)
- Listener de conectividade / sync ao reconectar (ENI-39)
- Câmera e GPS reais (E9 fase 2)
