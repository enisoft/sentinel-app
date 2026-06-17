# Última tarefa executada — ENI-27 · E10.0 Conectividade mínima

Pedido: camada de rede antes de upload/sync — login Supabase, `GET /me` no startup, catálogo offline (delta sync), config de ambiente, dropdowns no form. Sem TUS, sync de ocorrências, FGS ou painel.

Data: 2026-06-17

## O que foi feito

### 1. Config de ambiente

- **`.env.example`** — `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` (emulador: `10.0.2.2`)
- **`lib/core/config/app_config.dart`** — carrega `.env` ou fallback `.env.example`
- **`README.md`** — setup local documentado

### 2. Auth Supabase (P1)

- **`AuthGateway`** + **`SupabaseAuthGateway`** — login e-mail/senha, sessão/JWT persistidos pelo SDK
- **`LoginScreen`** — UI de login com validação
- **`AuthGate`** — redireciona login ↔ bootstrap conforme sessão
- **`FakeAuthGateway`** — testes sem rede

### 3. API Laravel + perfil (P1)

- **`ApiClient`** — `GET /me`, `GET /catalog/{observables|categories|municipalities}` com Bearer JWT
- **`OperatorProfile`** — modelo alinhado ao contrato backend
- **`CachedOperatorProfiles`** (drift) + **`OperatorProfileRepository`** — cache offline do `/me`
- **`ApiException`** — 401 dispara logout no bootstrap

### 4. Catálogo offline (P2)

- Drift schema **v4**: `categories`, `observables`, `municipalities`, `catalog_sync_cursors`
- **`CatalogSyncService`** — delta por `updated_since`, upsert `items`, delete `deleted_ids`, cursor `server_time`
- **`CatalogRepository`** — leitura local + `seedForTesting`

### 5. Bootstrap + UI

- **`BootstrapService`** — `/me` + sync das 3 entidades de catálogo
- **`AppBootstrapScreen`** — spinner; falha de catálogo não bloqueia captura (banner + retry)
- **`main.dart`** → `AuthGate` (não mais direto na home)
- **`CaptureHomeScreen`** — logout + aviso de catálogo
- **`OccurrenceDraftFormScreen`** — dropdowns de categoria/observável do catálogo local

## Dependências adicionadas

`supabase_flutter`, `http`, `flutter_dotenv`

## Resultado dos testes

```
flutter test → 32 passed (23 anteriores + 9 novos)
```

Novos testes:
- `test/data/remote/api_client_test.dart` (4)
- `test/data/repositories/operator_profile_repository_test.dart` (1)
- `test/data/services/catalog_sync_service_test.dart` (2)
- `test/presentation/auth/login_screen_test.dart` (2)
- `test/presentation/capture/capture_flow_test.dart` — atualizado para dropdowns + seed catálogo

## Verificação manual

1. `cd sentinel-backend`: `npx supabase start`, `php artisan migrate`, `php artisan db:seed`, `php artisan serve`
2. `php artisan sentinel:create-operator operador@test.com Senha123! "Operador"`
3. Copiar `sentinel-app/.env.example` → `.env`, preencher `SUPABASE_ANON_KEY` (`npx supabase status -o env`)
4. `flutter run` no emulador → login → bootstrap → captura → form com dropdowns

## Fora de escopo (mantido)

`SyncGateway` implementação, TUS, `POST /occurrences/sync`, `POST /check-ins/sync`, worker/FGS, câmera/GPS reais, inbox tasks, alterações backend/Linear.

## Próximo passo sugerido

E10.1+ — implementar `SyncGateway` (upload mídia + sync JSON de ocorrências/check-ins).
