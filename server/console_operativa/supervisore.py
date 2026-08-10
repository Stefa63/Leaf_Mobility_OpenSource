"""! @file supervisore.py
@brief Avvio/arresto del processo runtime (uvicorn) e verifica del tunnel Cloudflare.
"""

from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

import psutil

from server.console_operativa.client_controllo import ClientControllo
from server.runtime.impostazioni import RADICE_SERVER, Impostazioni

#! Radice del repository (cartella che contiene il pacchetto server/).
_RADICE_REPO = RADICE_SERVER.parent
#! Target d'import uvicorn dell'app del runtime.
_TARGET = "server.runtime.app_factory:app"
#! Sottodominio (Public Hostname) del tunnel Cloudflare dedicato all'esame.
SOTTODOMINIO_TUNNEL = "api"
#! Dominio registrato su Cloudflare.
DOMINIO_TUNNEL = "leafmobility.org"
#! URL pubblico completo del tunnel Cloudflare.
URL_TUNNEL = f"https://{SOTTODOMINIO_TUNNEL}.{DOMINIO_TUNNEL}"


class Supervisore:
    """! @brief Avvia e arresta il runtime come processo indipendente.

    Lancia uvicorn in un processo separato che sopravvive alla console (cosi'
    altre console possono agganciarsi) e lo arresta in modo controllato leggendo
    il file PID scritto dal runtime. Garantisce che un solo runtime sia attivo.

    @param impostazioni Configurazione del runtime (host/porta/worker).
    """

    def __init__(self, impostazioni: Impostazioni) -> None:
        """! @brief Inizializza il supervisore.
        @param impostazioni Configurazione del runtime.
        """
        self._imp = impostazioni
        self._client = ClientControllo(impostazioni.base_url)
        self._tunnel_attivo: bool = False
        self._tunnel_url: str = ""

    @property
    def _file_pid(self) -> Path:
        """! @brief Percorso del file PID del runtime.
        @return Path di server.pid.
        """
        return self._imp.dati_dir / "server.pid"

    def in_esecuzione(self) -> bool:
        """! @brief Verifica se il runtime e' attivo e raggiungibile.
        @return True se l'health check loopback risponde.
        """
        return self._client.raggiungibile()

    def avvia(self, attesa_s: float = 15.0) -> bool:
        """! @brief Avvia il runtime se non gia' attivo.
        @param attesa_s Secondi massimi di attesa che il server risponda.
        @return True se al termine il runtime e' raggiungibile.
        @throws RuntimeError Se il processo termina prematuramente.
        """
        if self.in_esecuzione():
            return True
        self._imp.dati_dir.mkdir(parents=True, exist_ok=True)
        log = (self._imp.dati_dir / "server.log").open("a", encoding="utf-8")
        comando = [
            sys.executable,
            "-m",
            "uvicorn",
            _TARGET,
            "--host",
            self._imp.host,
            "--port",
            str(self._imp.porta),
        ]
        if self._imp.workers > 1:
            comando += ["--workers", str(self._imp.workers)]
        # Processo indipendente: sopravvive alla chiusura della console.
        flag = getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)
        flag |= getattr(subprocess, "DETACHED_PROCESS", 0x00000008)
        flag |= getattr(subprocess, "CREATE_NO_WINDOW", 0x08000000)

        proc = subprocess.Popen(
            comando,
            cwd=str(_RADICE_REPO),
            stdout=log,
            stderr=log,
            stdin=subprocess.DEVNULL,
            creationflags=flag,
        )
        log.close()  # Chiude l'handle nel padre (il figlio ne ha una copia)
        scadenza = time.monotonic() + attesa_s
        while time.monotonic() < scadenza:
            if proc.poll() is not None:
                raise RuntimeError("il runtime e' terminato in avvio (vedi server.log)")
            if self.in_esecuzione():
                return True
            time.sleep(0.3)
        return self.in_esecuzione()

    def arresta(self, attesa_s: float = 10.0) -> bool:
        """! @brief Arresta il runtime in modo controllato tramite il PID.
        @param attesa_s Secondi massimi di attesa per la terminazione.
        @return True se al termine il runtime non e' piu' attivo.
        """
        if not self._file_pid.is_file():
            return not self.in_esecuzione()
        try:
            pid = int(self._file_pid.read_text(encoding="utf-8").strip())
            proc = psutil.Process(pid)
        except (ValueError, psutil.NoSuchProcess):
            self._file_pid.unlink(missing_ok=True)
            return True
        proc.terminate()
        try:
            proc.wait(timeout=attesa_s)
        except psutil.TimeoutExpired:
            proc.kill()
        self._file_pid.unlink(missing_ok=True)
        self.arresta_tunnel()
        return not self.in_esecuzione()

    # ── Tunnel Cloudflare ───────────────────────────────────────────────

    def avvia_tunnel(self) -> str:
        """! @brief Constata lo stato del tunnel Cloudflare (servizio Windows).

        A differenza del precedente tunnel in-process, cloudflared gira come
        servizio Windows autonomo: il supervisore non lo avvia né lo arresta, ne
        verifica solo lo stato (read-only) e restituisce l'URL pubblica del
        Public Hostname instradato verso il runtime.
        @return URL pubblica del tunnel (https://api.leafmobility.org).
        """
        self._tunnel_attivo = self._servizio_cloudflared_attivo()
        self._tunnel_url = URL_TUNNEL if self._tunnel_attivo else ""
        return self._tunnel_url or URL_TUNNEL

    def arresta_tunnel(self) -> None:
        """! @brief Azzera lo stato locale del tunnel.

        Non agisce sul servizio Windows cloudflared, che sopravvive all'arresto
        del runtime (è infrastruttura di sistema indipendente).
        """
        self._tunnel_attivo = False
        self._tunnel_url = ""

    @staticmethod
    def _servizio_cloudflared_attivo() -> bool:
        """! @brief Verifica (read-only) se cloudflared è in esecuzione.
        @return True se un processo cloudflared risulta attivo sull'host.
        """
        for proc in psutil.process_iter(["name"]):
            try:
                nome = (proc.info["name"] or "").lower()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
            if "cloudflared" in nome:
                return True
        return False

    @property
    def tunnel_attivo(self) -> bool:
        """! @brief Indica se il tunnel e' attivo."""
        return self._tunnel_attivo

    @property
    def tunnel_url(self) -> str:
        """! @brief URL pubblica del tunnel attivo."""
        return self._tunnel_url
