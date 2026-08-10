#!/bin/bash
# Script per l'installazione e l'avvio rapido in locale di Leaf Mobility.
# Questo script installa le dipendenze Python e Flutter, copia l'ambiente di default 
# ed esegue i test iniziali. Non richiede permessi di root, ma richiede
# Python3 e Flutter già configurati nel PATH.

echo -e "\e[32m=========================================\e[0m"
echo -e "\e[32m   Setup Ambiente di Sviluppo Leaf       \e[0m"
echo -e "\e[32m=========================================\e[0m"

# Memorizza la directory radice
ROOT_DIR=$(pwd)

# 1. Configurazione Server
echo -e "\n\e[36m[1] Configurazione Server (Python)...\e[0m"
cd "$ROOT_DIR/server" || exit

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "Creato .env da .env.example"
    else
        echo "File .env.example non trovato nel server."
    fi
fi

# Creazione ambiente virtuale
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo -e "\e[33mEseguo i test server (pytest)...\e[0m"
pytest -v
deactivate

cd "$ROOT_DIR" || exit

# 2. Configurazione Client Mobile
echo -e "\n\e[36m[2] Configurazione Client Mobile (Flutter)...\e[0m"
if [ -d "$ROOT_DIR/client/app_mobile_utente" ]; then
    cd "$ROOT_DIR/client/app_mobile_utente" || exit
    flutter pub get
    echo -e "\e[33mEseguo i test client (flutter test)...\e[0m"
    flutter test
else
    echo "Directory client/app_mobile_utente non trovata."
fi

cd "$ROOT_DIR" || exit

# 3. Configurazione Client Web Dashboard
echo -e "\n\e[36m[3] Configurazione Client Web Dashboard (Flutter)...\e[0m"
if [ -d "$ROOT_DIR/client/web_dashboard" ]; then
    cd "$ROOT_DIR/client/web_dashboard" || exit

    if [ ! -f "web/maps_config.js" ]; then
        if [ -f "web/maps_config.js.example" ]; then
            cp web/maps_config.js.example web/maps_config.js
            echo "Creato maps_config.js da maps_config.js.example"
        fi
    fi

    flutter pub get
    echo -e "\e[33mEseguo i test client web (flutter test)...\e[0m"
    flutter test
else
    echo "Directory client/web_dashboard non trovata. Skip."
fi

cd "$ROOT_DIR" || exit

echo -e "\n\e[32m=========================================\e[0m"
echo -e "\e[32m Setup completato con successo!          \e[0m"
echo -e "\e[32m Puoi avviare il server usando uvicorn e \e[0m"
echo -e "\e[32m l'app mobile usando flutter run.        \e[0m"
echo -e "\e[32m=========================================\e[0m"
