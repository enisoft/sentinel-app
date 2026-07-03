# Última tarefa executada — ENI-56: preview ao adicionar mídia

**Status: implementado** — verificação manual G56 pendente

**Linear:** ENI-56 — Corrigir "adicionar mídia" capturando às cegas (sem preview)

Data: 2026-07-02

---

## Bug

No fluxo de anexar 2ª+ mídia, o botão **"Adicionar mídia"** chamava `addMediaToDraft()` → `DeviceCameraSource.capture()` direto, sem UI de preview. A 1ª foto (via home) já mostrava `InAppCameraPreview`; as seguintes capturavam às cegas.

## Causa

`OccurrenceDraftFormScreen._onAddMedia` invocava o serviço sem navegar para tela com preview.

## Correção

| Arquivo | Mudança |
|---------|---------|
| `lib/presentation/capture/in_app_capture_screen.dart` | **Nova** — tela reutilizando `InAppCameraPreview` + botão de captura (mesma UX da home) |
| `lib/presentation/capture/occurrence_draft_form_screen.dart` | "Adicionar mídia" → `Navigator.push(InAppCaptureScreen)` → `attachCaptureToDraft` |
| `lib/data/services/capture_occurrence_service.dart` | `attachCaptureToDraft` (anexa `CaptureResult` já capturado); `addMediaToDraft` delega (testes unitários) |

### Fluxo

1. Form → **Adicionar mídia** → abre `InAppCaptureScreen` com preview ao vivo
2. Operador enquadra → 1 toque → `pop(CaptureResult)`
3. Volta ao form com mídia anexada ao rascunho atual

---

## Testes (`flutter test` — 113 passed)

- Widget: `add media opens capture preview screen before attaching`
- Widget: `add and remove media` — passa pela tela de preview antes de anexar
- Unit: `attachCaptureToDraft attaches pre-captured media without calling camera`
- Demais testes ENI-56 mantidos

```
00:05 +113: All tests passed!
```

---

## Verificação manual G56 (aceite — pendente)

1. Capturar 1ª foto → form → **Adicionar mídia**
2. **Esperado:** abre preview da câmera → enquadra → captura → 2ª mídia anexada
3. Repetir para 3ª foto — todas com preview

---

## Auditoria

Não exigida — correção de UX de captura; sem mudança de contrato/persistência.
