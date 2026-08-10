<#
.SYNOPSIS
Script per l'installazione e l'avvio rapido in locale di Leaf Mobility.

.DESCRIPTION
Questo script installa le dipendenze Python e Flutter, copia l'ambiente di default 
ed esegue i test iniziali. Non richiede permessi di amministratore, ma richiede
Python e Flutter già configurati nel PATH.
#>

Write-Host "=========================================" -ForegroundColor Green
Write-Host "   Setup Ambiente di Sviluppo Leaf       " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 1. Configurazione Server
Write-Host "`n[1] Configurazione Server (Python)..." -ForegroundColor Cyan
Set-Location -Path "$PSScriptRoot\server"

if (-Not (Test-Path ".env")) {
    Copy-Item ".env.example" -Destination ".env"
    Write-Host "Creato .env da .env.example"
}

# Creazione ambiente virtuale
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt

Write-Host "Eseguo i test server (pytest)..." -ForegroundColor Yellow
pytest -v

Set-Location -Path $PSScriptRoot

# 2. Configurazione Client
Write-Host "`n[2] Configurazione Client Mobile (Flutter)..." -ForegroundColor Cyan
Set-Location -Path "$PSScriptRoot\client\app_mobile_utente"

flutter pub get

Write-Host "Eseguo i test client (flutter test)..." -ForegroundColor Yellow
flutter test

Set-Location -Path $PSScriptRoot

# 3. Configurazione Client Web Dashboard
Write-Host "`n[3] Configurazione Client Web Dashboard (Flutter)..." -ForegroundColor Cyan
Set-Location -Path "$PSScriptRoot\client\web_dashboard"

if (-Not (Test-Path "web\maps_config.js")) {
    if (Test-Path "web\maps_config.js.example") {
        Copy-Item "web\maps_config.js.example" -Destination "web\maps_config.js"
        Write-Host "Creato maps_config.js da maps_config.js.example"
    }
}

flutter pub get

Write-Host "Eseguo i test client web (flutter test)..." -ForegroundColor Yellow
flutter test

Set-Location -Path $PSScriptRoot

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host " Setup completato con successo!          " -ForegroundColor Green
Write-Host " Puoi avviare il server usando uvicorn e " -ForegroundColor Green
Write-Host " l'app mobile usando flutter run.        " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
