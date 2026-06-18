# sentinel-app

App móvel **offline-first** do ecossistema Sentinel (Flutter/Android). Tudo é salvo
localmente primeiro e sincronizado depois.

**Arquitetura detalhada (estado pós-E10):** [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md)

Documentação de referência: [`docs/REFERENCES.md`](docs/REFERENCES.md).

## Estado atual (E10)

| Sub-épico | Status |
|-----------|--------|
| E10.0 — login Supabase, `/me`, catálogo offline | ✅ |
| E10.1 — `SyncGatewayHttp` (`POST /occurrences/sync`) | ✅ |
| E10.2 — upload TUS (`MediaUploader` / `TusMediaUploader`) | ✅ |
| E10.3a — background (FGS + UIDT) | ⏳ pendente |
| E10.3b — política Wi-Fi para vídeo | ⏳ pendente |
| E9 fase 2 — câmera real | ⏳ pendente (`FakeDeviceCameraSource` em produção) |

## Arquitetura (resumo)

Estrutura **layer-first**:

```
lib/
  app/           # bootstrap, DI (get_it)
  core/          # config, máquina de estados da fila
  domain/        # contratos (gateways, models)
  data/          # drift, repositórios, remote API, TUS
  presentation/  # telas e widgets
```

**Persistência:** [drift](https://drift.simonbinder.eu/) (SQLite) — ocorrências, fila de sync,
catálogo offline, perfil em cache.

**Sessão:** JWT em `flutter_secure_storage` (Keystore), não SharedPreferences (ENI-33).

## Configuração de ambiente

1. Copie `.env.example` para `.env` na raiz do projeto.
2. Preencha as variáveis:

| Variável | Exemplo (emulador) |
|----------|-------------------|
| `SUPABASE_URL` | `http://10.0.2.2:54321` |
| `SUPABASE_ANON_KEY` | saída de `npx supabase status -o env` |
| `API_BASE_URL` | `http://10.0.2.2:8000/api/v1` |

**Emulador Android:** `10.0.2.2` = localhost do host.

**Device físico:** use o IP da máquina na rede local (não `10.0.2.2`).

```bash
# No sentinel-backend:
npx supabase status -o env   # SUPABASE_ANON_KEY
php artisan serve            # API em :8000
php artisan migrate
php artisan db:seed
php artisan sentinel:create-operator operador@test.com Senha123! "Operador Teste"
```

## Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```

## Fluxo offline-first (resumo)

- Sem rede no bootstrap: operador **permanece logado** se já tiver perfil em cache; só
  `401` HTTP real desloga (ENI-38).
- Captura offline → fila Drift → sync (TUS mídia, depois JSON) no cold start ou após
  confirmar rascunho.
- Sync ao reconectar com app aberto: **não** implementado (melhoria ENI-39).

Ver [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) para diagramas de componentes, path
canônico `occurrences/{id}/{media_id}.{ext}` e detalhes de TUS.
