# Baixa os arquivos auxiliares do drift para rodar o app na web (Chrome).
#
# Coloca sqlite3.wasm e drift_worker.js em app/web/, nas versoes compativeis
# com o pubspec.lock atual (drift 2.31.0 / sqlite3 2.9.4).
#
# Uso (PowerShell), a partir da pasta app:
#   ./tool/fetch_web_assets.ps1
#
# No Android esses arquivos NAO sao necessarios.

$ErrorActionPreference = "Stop"

$driftVersion = "2.31.0"
$sqlite3Version = "2.9.4"

$driftWorkerUrl = "https://github.com/simolus3/drift/releases/download/drift-$driftVersion/drift_worker.js"
$sqlite3WasmUrl = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$sqlite3Version/sqlite3.wasm"

# Resolve a pasta web/ relativa a este script (app/tool -> app/web).
$webDir = Join-Path (Split-Path $PSScriptRoot -Parent) "web"
if (-not (Test-Path $webDir)) {
    New-Item -ItemType Directory -Path $webDir | Out-Null
}

Write-Host "Baixando drift_worker.js (drift $driftVersion)..."
Invoke-WebRequest -Uri $driftWorkerUrl -OutFile (Join-Path $webDir "drift_worker.js")

Write-Host "Baixando sqlite3.wasm (sqlite3 $sqlite3Version)..."
Invoke-WebRequest -Uri $sqlite3WasmUrl -OutFile (Join-Path $webDir "sqlite3.wasm")

Write-Host "Pronto. Arquivos em: $webDir"
Write-Host "Agora rode: flutter run -d chrome"
