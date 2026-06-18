# Diagnóstico da fila de sync no device (Drift)
# Uso: .\tools\debug_sync_queue.ps1 [-DeviceId ZF525FJSZ2]

param(
    [string]$DeviceId = ""
)

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    Write-Error "adb não encontrado em $adb"
    exit 1
}

$adbArgs = @()
if ($DeviceId) { $adbArgs += "-s", $DeviceId }

$devices = & $adb @adbArgs devices
Write-Host "=== Devices ===" -ForegroundColor Cyan
Write-Host $devices

$online = $devices | Select-String "device$"
if (-not $online) {
    Write-Host "`nNenhum device online. Conecte USB, desbloqueie e aceite depuração USB." -ForegroundColor Yellow
    exit 1
}

$outDb = Join-Path $PSScriptRoot "..\sentinel-device.db"
$outDb = [System.IO.Path]::GetFullPath($outDb)

Write-Host "`n=== Copiando sentinel.db ===" -ForegroundColor Cyan
$rawOut = "$outDb.tmp"
if (Test-Path $rawOut) { Remove-Item $rawOut -Force }
$pullArgs = @()
if ($DeviceId) { $pullArgs += "-s", $DeviceId }
$pullArgs += "exec-out", "run-as", "com.sentinel.sentinel_app", "cat", "app_flutter/sentinel.db"
$p = Start-Process -FilePath $adb -ArgumentList $pullArgs -RedirectStandardOutput $rawOut -NoNewWindow -Wait -PassThru
if ($p.ExitCode -ne 0) {
    Write-Host "adb exec-out falhou (exit $($p.ExitCode))" -ForegroundColor Red
    exit 1
}
Move-Item -Force $rawOut $outDb

if (-not (Test-Path $outDb) -or (Get-Item $outDb).Length -lt 100) {
    Write-Host "Falha ao copiar DB. App instalado via flutter run (debug)?" -ForegroundColor Red
    exit 1
}

Write-Host "DB salvo: $outDb ($((Get-Item $outDb).Length) bytes)" -ForegroundColor Green

$dart = Get-Command dart -ErrorAction SilentlyContinue
if ($dart) {
    Push-Location (Join-Path $PSScriptRoot "..")
    dart run tools/query_sentinel_db.dart $outDb
    Pop-Location
    exit 0
}

$sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $sqlite) {
    Write-Host "`nsqlite3 não está no PATH. Abra $outDb no DB Browser for SQLite." -ForegroundColor Yellow
    exit 0
}

function Invoke-DbQuery($sql) {
    Write-Host "`n--- $sql ---" -ForegroundColor Cyan
    sqlite3 $outDb $sql
}

Invoke-DbQuery "SELECT sync_state, status, COUNT(*) AS n FROM occurrences GROUP BY sync_state, status ORDER BY n DESC;"
Invoke-DbQuery @"
SELECT 'QUEUE_OCC' AS src, id, status, sync_state, failed_phase, substr(failed_reason,1,60) AS reason
FROM occurrences
WHERE status='pending' AND sync_state != 'synced'
  AND NOT (sync_state='failed' AND failed_reason LIKE 'validation:%');
"@
Invoke-DbQuery "SELECT 'QUEUE_CI' AS src, id, sync_state, failed_phase, substr(failed_reason,1,60) FROM check_ins WHERE sync_state != 'synced';"
Invoke-DbQuery "SELECT 'DRAFTS' AS src, id, sync_state, substr(failed_reason,1,60) FROM occurrences WHERE status='draft';"
Invoke-DbQuery "SELECT 'DEAD_VALIDATION' AS src, id, status, sync_state, substr(failed_reason,1,80) FROM occurrences WHERE failed_reason LIKE 'validation:%';"
Invoke-DbQuery "SELECT id, sync_state, synced_at FROM occurrences ORDER BY created_local_at DESC LIMIT 5;"
