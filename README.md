# sentinel-app

App móvel **offline-first** do ecossistema Sentinel (Flutter/Android). Tudo é salvo
localmente primeiro e sincronizado depois.

Documentação de referência: [`docs/REFERENCES.md`](docs/REFERENCES.md).

## Arquitetura

Estrutura **layer-first** (camadas horizontais):

```
lib/
  app/           # bootstrap, DI
  core/          # regras puras (máquina de estados da fila)
  domain/        # contratos (SyncGateway — sem implementação nesta fase)
  data/          # drift, repositórios
  presentation/  # (fase futura) telas e widgets
```

**DI:** [`get_it`](https://pub.dev/packages/get_it) — registro leve de banco e repositórios sem camada de UI; Riverpod entra quando houver `presentation/` com estado reativo.

**Persistência:** [drift](https://drift.simonbinder.eu/) (SQLite) com tabelas `occurrences`, `occurrence_media`, `check_ins`.

## Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```

## Fila de sync (nesta fase)

Estados: `local_saved → media_uploading → media_done → json_syncing → synced` (+ `failed`).

Repositórios expõem transições de estado **sem rede**. A fronteira futura é
`SyncGateway` (`lib/domain/gateways/sync_gateway.dart`).

## Fora de escopo (fases futuras)

- UI de captura, câmera, permissões
- Upload TUS e chamadas HTTP reais
- Supabase Auth, catálogo offline, inbox de tasks
- WorkManager / Foreground Service
