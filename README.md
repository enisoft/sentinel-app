# sentinel-app

App móvel **offline-first** do ecossistema Sentinel (Flutter/Android). Tudo é salvo
localmente primeiro e sincronizado depois.

Documentação de referência: [`docs/REFERENCES.md`](docs/REFERENCES.md).

## Arquitetura

Estrutura **layer-first** (camadas horizontais):

```
lib/
  app/           # bootstrap, DI
  core/          # config, regras puras (máquina de estados da fila)
  domain/        # contratos (gateways, models)
  data/          # drift, repositórios, remote API
  presentation/  # telas e widgets
```

**DI:** [`get_it`](https://pub.dev/packages/get_it) — registro leve de banco, auth e repositórios.

**Persistência:** [drift](https://drift.simonbinder.eu/) (SQLite) com tabelas operacionais + catálogo offline.

## Configuração de ambiente

1. Copie `.env.example` para `.env` na raiz do projeto.
2. Preencha as variáveis (emulador Android usa `10.0.2.2` para localhost do host):

```bash
# No sentinel-backend:
npx supabase status -o env   # SUPABASE_ANON_KEY
php artisan serve            # API em :8000
php artisan migrate
php artisan db:seed
php artisan sentinel:create-operator operador@test.com Senha123! "Operador Teste"
```

| Variável | Exemplo (emulador) |
|----------|-------------------|
| `SUPABASE_URL` | `http://10.0.2.2:54321` |
| `SUPABASE_ANON_KEY` | saída de `npx supabase status -o env` |
| `API_BASE_URL` | `http://10.0.2.2:8000/api/v1` |

Em dispositivo físico, substitua `10.0.2.2` pelo IP da máquina na rede local.

Adicione `.env` em `pubspec.yaml` → `assets` localmente se preferir não editar `.env.example`.

## Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```

## Conectividade (E10.0)

- Login Supabase (e-mail/senha) → JWT persistido
- `GET /api/v1/me` no startup → perfil em cache drift
- Catálogo delta (`observables`, `categories`, `municipalities`) → drift
- Falha de catálogo não bloqueia captura offline

## Fila de sync

Estados: `local_saved → media_uploading → media_done → json_syncing → synced` (+ `failed`).

A fronteira de upload/sync HTTP é `SyncGateway` (fase futura).

## Fora de escopo (fases futuras)

- Upload TUS e `POST /occurrences/sync` / `POST /check-ins/sync`
- Câmera/GPS reais no device (E9-fase2)
- Inbox de tasks
- WorkManager / Foreground Service
