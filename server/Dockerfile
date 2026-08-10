FROM python:3.11-slim

# Imposta la directory di lavoro
WORKDIR /app

# Variabili d'ambiente per Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Installa dipendenze di sistema necessarie per compilazione (se servono per cryptography/passlib)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Copia i requisiti e installa le librerie
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia il resto del codice server (dal contesto build server/)
COPY . .

# Esponi la porta
EXPOSE 8000

# Comando di default per avviare il server
CMD ["python", "-m", "runtime"]
