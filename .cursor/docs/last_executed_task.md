# Última tarefa executada — ENI-52 (correção): vídeo estável

**Status: implementado** — verificação manual G56/G86 pendente

**Linear:** ENI-52 — Vídeo real in-app: wakelock + estabilidade em gravação longa

Data: 2026-07-03

---

## Escopo

Correção do crash em gravação ~5 min no G56 (~4 min, arquivo 350 MB+). Manter tela ligada durante gravação (wakelock). Diagnosticar e corrigir gargalos de memória no pipeline pós-captura. Limite rígido de 5 min mantido.

**Fora de escopo:** compactação H.264 pós-captura (ENI-47).

---

## Diagnóstico (antes da correção)

| Componente | Leitura do arquivo | Veredito |
|------------|-------------------|----------|
| **Hash** (`CryptoHashService`) | `sha256.bind(file.openRead())` — streaming por chunks do SO | ✅ Já em streaming; não carrega arquivo inteiro em RAM |
| **TUS** (`TusMediaUploader`) | `tus_client_dart` `_getData()` → `file.openRead(start, end)` com `maxChunkSize` 6 MB | ✅ Já em streaming; pico ~6 MB em RAM por chunk |
| **Stop vídeo** (`DeviceCameraSource`) | `File.copy(temp → dest)` duplicava o arquivo em disco | ⚠️ Pico de I/O e ~2× espaço em disco no stop (não OOM direto, mas pressiona device fraco) |
| **Captura** | `ResolutionPreset.high` (~1080p) | ⚠️ **Provável causa principal do crash** — encoder + buffers do preview acumulam RAM ao longo de 4+ min; bitrate alto → ~70 MB/min → 5 min ≈ 350 MB+ (bate com relato G56) |
| **Tela apagando** | Sem wakelock | ⚠️ **Causa secundária confirmada** — tela apaga → app pausa → gravação interrompida/perdida |

**Extrapolação de tamanho (~1 min, G56, antes da correção):**
- `ResolutionPreset.high`: estimativa **~60–80 MB/min** → 5 min ≈ **300–400 MB** (consistente com crash ~4 min / 350 MB+)
- `ResolutionPreset.medium` (720p, após correção): estimativa **~25–40 MB/min** → 5 min ≈ **125–200 MB**

Não foi possível rodar logcat/memory profiler neste ambiente (sem device físico conectado). O diagnóstico estático aponta encoder em alta resolução + ausência de wakelock como causas; hash/TUS não precisaram de alteração.

---

## Implementação

| Arquivo | Mudança |
|---------|---------|
| `pubspec.yaml` | `wakelock_plus` — manter tela ligada durante gravação |
| `lib/presentation/capture/in_app_capture_controls.dart` | `WakelockPlus.enable()` ao iniciar gravação; `disable()` ao parar/dispose; fire-and-forget para não bloquear UI |
| `lib/data/device/device_camera_source.dart` | `ResolutionPreset.medium` (~720p) em vez de `high`; `rename` com fallback `copy` no stop (evita duplicar arquivo grande em disco) |
| `test/data/device/crypto_hash_service_test.dart` | Teste de hash em arquivo **8 MB** escrito em chunks de 64 KB |

### Inalterados (já corretos)

- `lib/data/device/crypto_hash_service.dart` — streaming SHA-256
- `lib/data/remote/tus_media_uploader.dart` — TUS chunked 6 MB
- `lib/core/capture/video_recording_policy.dart` — limite 300s

### Fluxo corrigido

1. Operador inicia vídeo → **wakelock ativo** (tela não apaga)
2. Gravação em **720p** — menor pressão de RAM do encoder e arquivo menor
3. Auto-stop em 05:00 → `stopVideoRecording` → **rename** (sem cópia duplicada quando possível)
4. Hash streaming → rascunho → upload TUS chunked (inalterado)

---

## Testes (`flutter test` — 124 passed)

```
00:05 +124: All tests passed!
```

- `test/core/capture/video_recording_policy_test.dart` — limite 300s (mantido)
- `test/data/device/crypto_hash_service_test.dart` — hash 8 MB via streaming
- `test/presentation/capture/capture_flow_test.dart` — gravação vídeo anexa ao rascunho (mantido)

---

## Arquivos tocados

**Alterados:**
- `pubspec.yaml`
- `lib/presentation/capture/in_app_capture_controls.dart`
- `lib/data/device/device_camera_source.dart`
- `test/data/device/crypto_hash_service_test.dart`
- `.cursor/docs/last_executed_task.md`

---

## Verificação manual G56 / G86 (aceite — pendente)

1. Gravar **5 min completos** → tela permanece ligada → corta em 05:00 → salva → **não crasha**
2. Relatar **tamanho real do arquivo** (esperado ~125–200 MB em 720p vs ~350 MB+ antes)
3. Hash + upload TUS → Postgres + Storage (`content_hash`, path `.mp4`)
4. Vídeo + foto na mesma ocorrência → ambos sobem
5. Cortar rede no meio do upload do vídeo → retoma (TUS offset)

---

## Auditoria

Foco: integridade (hash streaming em arquivo grande) + estabilidade de memória (720p + wakelock). Hash e TUS já estavam corretos; ver [audit_2026-07-02_eni-52.md](audit_2026-07-02_eni-52.md) para contrato base.
