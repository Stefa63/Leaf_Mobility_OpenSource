<#
  serve_web_release.ps1 — Build + serve della WebDashboard in modalita' RELEASE.

  PERCHE': lo sviluppo "debug" sul web (flutter run -d chrome) usa il
  compilatore DDC, che scarica migliaia di moduli non ottimizzati -> caricamento
  lentissimo a freddo (anche >2 minuti). La build release e' compilata e
  minificata: il primo caricamento scende a pochi secondi. Usare questo script
  per visualizzazioni/demo, e la run config "main.dart (release web)" per il
  ciclo di sviluppo veloce.

  USO (dalla cartella client/web_dashboard):
      ./tool/serve_web_release.ps1            # build + serve su http://localhost:8080
      ./tool/serve_web_release.ps1 -Port 9000 # porta personalizzata
      ./tool/serve_web_release.ps1 -NoBuild   # salta la build, serve build/web esistente
#>
param(
    [int]$Port = 8080,
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot   # client/web_dashboard
Set-Location $root

if (-not $NoBuild) {
    Write-Host "==> flutter build web --release" -ForegroundColor Green
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    flutter build web --release
    $sw.Stop()
    Write-Host ("==> Build completata in {0:N1}s" -f $sw.Elapsed.TotalSeconds) -ForegroundColor Green
}

$webDir = Join-Path $root "build/web"
if (-not (Test-Path $webDir)) {
    throw "build/web non trovata: esegui senza -NoBuild per generarla."
}

Write-Host "==> Serve $webDir su http://localhost:$Port (Ctrl+C per fermare)" -ForegroundColor Green
# Server statico standard via Python (presente nell'ambiente): nessuna dipendenza aggiuntiva.
Set-Location $webDir
python -m http.server $Port
