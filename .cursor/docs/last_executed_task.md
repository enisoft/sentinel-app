# Última tarefa executada — ENI-58: zoom da câmera por cliques (níveis)

**Status: implementado** — verificação manual G86 pendente

**Linear:** ENI-58 — zoom por níveis no preview (foto e vídeo), sem gesto contínuo

Data: 2026-07-04

---

## Escopo

Botões de nível de zoom no preview in-app (`camera`), fluxo pega-tudo (ENI-60). Troca instantânea via `setZoomLevel`; sem pinça/scroll.

**Fora de escopo:** hash/GPS/pipeline/limite de vídeo/wakelock (ENI-50/52/60 intactos); auditoria de integridade.

---

## Comportamento

| Elemento | Comportamento |
|----------|----------------|
| Níveis-alvo | 0.5x (só se ultrawide / `min ≤ 0.5`), 1x, 2x, 4x (só se `max ≥ 4`) |
| Device | `getMinZoomLevel()` / `getMaxZoomLevel()` do `CameraController` |
| UI | Botões no preview; nível ativo destacado (círculo branco) |
| Sessão | Nível persiste entre clipes na mesma tela de captura (não reseta) |
| Gesto | Nenhum — só clique no nível |

G86: sem tele dedicada; 4x é zoom digital se o max permitir.

---

## Implementação

| Arquivo | Mudança |
|---------|---------|
| `lib/core/capture/camera_zoom_levels.dart` | Mapeamento min/max → níveis; `CameraZoomSession` (select + persistência) |
| `lib/data/device/device_camera_source.dart` | `getMinZoomLevel` / `getMaxZoomLevel` / `setZoomLevel` |
| `lib/presentation/capture/camera_zoom_controls.dart` | Botões de nível no preview |
| `lib/presentation/capture/in_app_camera_preview.dart` | Overlay dos controles de zoom |
| `test/core/capture/camera_zoom_levels_test.dart` | Mapeamento + select → applyZoom |
| `test/presentation/capture/camera_zoom_controls_test.dart` | UI: níveis, tap chama setZoomLevel |

---

## Testes (`flutter test` — 152 passed)

```
00:07 +152: All tests passed!
```

Cenários ENI-58:

- mapeamento respeita min/max (sem forçar 0.5x / 4x fora do range)
- `CameraZoomSession.select` chama `applyZoom` com o nível correspondente
- nível ativo persiste na sessão entre seleções
- widget: tap em 2x / 0.5x chama `setZoomLevel` correspondente
- controles ocultos quando há um único nível

---

## Arquivos tocados

**Novos:**

- `lib/core/capture/camera_zoom_levels.dart`
- `lib/presentation/capture/camera_zoom_controls.dart`
- `test/core/capture/camera_zoom_levels_test.dart`
- `test/presentation/capture/camera_zoom_controls_test.dart`

**Alterados:**

- `lib/data/device/device_camera_source.dart`
- `lib/presentation/capture/in_app_camera_preview.dart`
- `.cursor/docs/last_executed_task.md`

---

## Verificação manual G86 (aceite — pendente)

1. Preview mostra botões de nível; tocar alterna o zoom na hora (foto e vídeo)
2. Gravar vídeo em 2x → zoom mantém durante a gravação
3. Capturas em diferentes zooms entram no carrinho normalmente (pega-tudo intacto)

---

## Auditoria

**Não escalada.** UI/câmera; não toca integridade nem contrato. Report + testes + device bastam.
