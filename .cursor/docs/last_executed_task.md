# Última tarefa executada — ENI-36 Fake de captura com bytes JPEG reais (TUS no device)

Pedido: fake de captura no DI de produção grava JPEG real em disco para validar upload TUS (ENI-29) em device sem câmera; manter fake de testes sem I/O; testes verdes.

Data: 2026-06-18

---

## Problema

`FakeCameraSource` devolvia `/fake/captures/photo.jpg` (path inexistente) → `TusMediaUploader` falhava com "Arquivo local não encontrado" → `media_uploading` falhava → JSON nunca era enviado.

---

## O que foi feito

### Separação device vs teste

| Classe | Uso | Comportamento |
|--------|-----|---------------|
| `FakeDeviceCameraSource` | DI produção (`_registerCaptureFakes`) | Grava JPEG mínimo válido em `getTemporaryDirectory()`; retorna path real + `image/jpeg` |
| `FakeCameraSource` | Testes (`configureDependenciesForTesting`) | Inalterado — path configurável, sem I/O |

### Geração de arquivo

- **`lib/data/fakes/minimal_jpeg_bytes.dart`** — constante `kMinimalJpegBytes` (JPEG 1×1 válido, ~169 bytes)
- **`lib/data/fakes/fake_device_camera_source.dart`**
  - `capture()` → `writeFakeCaptureJpeg()` → `fake_capture_{n}.jpg` no temp dir
  - `sizeBytes` = tamanho real do arquivo
  - `capturedAt` = `DateTime.now().toUtc()`
  - Hash/GPS continuam via `FakeHashService` / `FakeLocationSource` no DI

### DI

- **`lib/app/di.dart`** — `_registerCaptureFakes()` usa `FakeDeviceCameraSource()` em vez de `FakeCameraSource()`
- `configureDependenciesForTesting` mantém default `FakeCameraSource()` — 52+ testes headless sem path_provider

### Fora de escopo (respeitado)

- `TusMediaUploader`, contrato `CameraSource`, câmera real (E9 fase 2)

---

## Testes

### `flutter test`

```
00:03 +57: All tests passed!
```

(56 anteriores + 1 novo)

| Caso | Arquivo |
|------|---------|
| `writeFakeCaptureJpegTo` cria arquivo com bytes JPEG válidos (SOI/EOI) | `fake_device_camera_source_test.dart` |
| Demais 56 testes inalterados | suite existente |

---

## Verificação manual G56/G65 — confirmada (2026-06-18)

Pré-requisito: backend + Supabase local, operador logado, `.env` com IP LAN.

### 1. Captura → TUS (sem "arquivo não encontrado")

**Resultado:** OK — upload TUS concluído; sem `MediaUploadException` de arquivo ausente.

### 2. Supabase Studio — Storage → sentinel-media

**Resultado:** OK — objeto em `occurrences/{occurrence_id}/{media_id}.jpg`.

### 3. Postgres (Laravel)

```sql
SELECT o.id, o.reported_by,
       om.id AS media_id, om.path
FROM occurrences o
LEFT JOIN occurrence_media om ON om.occurrence_id = o.id
WHERE o.reported_by = '<uid-operador>'
ORDER BY o.created_at DESC
LIMIT 5;
```

**Resultado:** OK — ocorrência e `occurrence_media.path` canônico presentes.

### 4. storage.objects (RLS E6)

```sql
SELECT id, name, owner_id, bucket_id
FROM storage.objects
WHERE bucket_id = 'sentinel-media'
ORDER BY created_at DESC
LIMIT 5;
```

**Resultado:** OK — `owner_id` = uid do operador logado (RLS E6 confirmado).

---

## Arquivos tocados

| Arquivo | Ação |
|---------|------|
| `lib/data/fakes/minimal_jpeg_bytes.dart` | novo |
| `lib/data/fakes/fake_device_camera_source.dart` | novo |
| `lib/data/fakes/fake_camera_source.dart` | comentário — uso em testes |
| `lib/app/di.dart` | `FakeDeviceCameraSource` no DI produção |
| `test/data/fakes/fake_device_camera_source_test.dart` | novo |
| `.cursor/docs/last_executed_task.md` | este relatório |

---

<details>
<summary>Histórico — ENI-29 TUS, ENI-28, bootstrap 401</summary>

Ver `.cursor/docs/audit_20260618_eni29.md` e commits anteriores.

</details>
