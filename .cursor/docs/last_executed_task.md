# Fix build release sem internet (INTERNET permission)

**Tipo:** Bugfix Android manifest  
**Data:** 2026-07-10  
**Branch:** working tree

---

## Resumo

| Item | Status |
|------|--------|
| `INTERNET` no `AndroidManifest.xml` principal (`src/main`) | ✅ |
| `network_security_config.xml` bloqueando tráfego | ❌ não existe |
| Manifest release/prod removendo permissão | ❌ não há manifests extras |
| `versionCode` incrementado (`1.0.0+1` → `1.0.0+2`) | ✅ |
| AAB prod release gerado | ✅ |
| `INTERNET` no manifest merged `prodRelease` | ✅ confirmado |

---

## Diagnóstico

App funcionava em **debug/local** mas falhava no **release** (Play Store internal test) com:

```
SocketException: Failed host lookup ... errno 7
```

**Causa:** `android.permission.INTERNET` estava presente apenas nos manifests de **debug** e **profile** (injetados pelo template Flutter para hot reload), mas **ausente** em `android/app/src/main/AndroidManifest.xml`. Builds release/prod saíam sem acesso à rede.

---

## Correção

### 1. Permissão INTERNET no manifest principal

Adicionado em `android/app/src/main/AndroidManifest.xml` (dentro de `<manifest>`, antes de `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Vale para todos os build types e flavors (dev/prod, debug/release).

### 2. Network security config

Não existe `network_security_config.xml` no projeto — nada bloqueia HTTPS para `*.supabase.co` ou o host Heroku.

### 3. Manifests release/prod

Apenas 3 manifests Android no projeto:

| Caminho | INTERNET |
|---------|----------|
| `src/main/AndroidManifest.xml` | ✅ (corrigido) |
| `src/debug/AndroidManifest.xml` | ✅ (redundante, ok) |
| `src/profile/AndroidManifest.xml` | ✅ (redundante, ok) |

Nenhum manifest de release/prod remove permissões.

### 4. versionCode

`pubspec.yaml`: `1.0.0+1` → `1.0.0+2` (Play Console rejeita mesmo `versionCode`).

### 5. Build blocker colateral (GeneratedPluginRegistrant)

`android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` estava versionado indevidamente (deveria ser gerado — ver `android/.gitignore`). Referenciava `flutter_native_splash` (dev_dependency) e quebrava `compileProdReleaseJavaWithJavac`. Arquivo removido; Flutter regenera no build sem o plugin dev em release.

---

## Verificação

### Build

```powershell
flutter build appbundle --flavor prod --release -t lib/main_prod.dart
```

**Resultado:** ✅ `build\app\outputs\bundle\prodRelease\app-prod-release.aab` (~47,8 MB)

### Manifest merged prodRelease

`build/app/intermediates/merged_manifests/prodRelease/.../AndroidManifest.xml`:

- `package="com.enisoft.relato"`
- `android:versionCode="2"`
- `<uses-permission android:name="android.permission.INTERNET" />` — **presente** (linha 11)
- Sem `networkSecurityConfig`

### Checklist manual (pendente humano)

- [ ] Subir novo AAB (`versionCode` 2) no Play Console → internal test
- [ ] Login operador Cloud → `GET /me` OK (sem SocketException)
- [ ] Captura com mídia → sync Heroku → ocorrência no Postgres Cloud
- [ ] Objeto no bucket `sentinel-media`

Alternativa pré-upload: testar AAB release direto via `bundletool` no device.

---

## Arquivos alterados

- `android/app/src/main/AndroidManifest.xml` — `INTERNET`
- `pubspec.yaml` — `version: 1.0.0+2`
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` — **removido** (stale, gitignored)
