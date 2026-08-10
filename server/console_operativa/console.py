"""! @file console.py
@brief Console operativa a schermo intero (TUI prompt_toolkit) fedele al design handoff.

Layout: barra telemetria fissa in alto (sempre visibile), brand con mascotte e
stato, due box di comandi a destra, chat scrollabile con storico a sinistra e
prompt con cursore in basso a sinistra. I comandi e il backend di controllo sono
quelli gia' esistenti: l'output dei comandi viene reso da Rich, catturato in ANSI
e accodato alla chat.
"""

from __future__ import annotations

import contextlib
import io
import shlex
import threading
import time
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from typing import cast

import psutil
from prompt_toolkit.application import Application
from prompt_toolkit.buffer import Buffer
from prompt_toolkit.completion import WordCompleter
from prompt_toolkit.data_structures import Point
from prompt_toolkit.formatted_text import ANSI, StyleAndTextTuples, to_formatted_text
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.layout import HSplit, Layout, VSplit, Window
from prompt_toolkit.layout.controls import BufferControl, FormattedTextControl
from prompt_toolkit.layout.dimension import Dimension
from prompt_toolkit.widgets import Frame
from rich.console import Console
from rich.table import Table

from server.console_operativa.client_controllo import ClientControllo, ErroreControllo
from server.console_operativa.cronologia import CronologiaConsole
from server.console_operativa.mascotte import ALTEZZA_MASCOTTE, foglia_formattata
from server.console_operativa.supervisore import Supervisore
from server.console_operativa.tema import TEMA, colore_soglia, stile_tui
from server.runtime.impostazioni import Impostazioni

#! Metadati dei comandi: nome -> (sintassi, descrizione breve, aiuto esteso).
COMANDI: dict[str, tuple[str, str, str]] = {
    "start": (
        "start",
        "Avvia il runtime server.",
        "Avvia il processo del runtime (uvicorn) se non gia' attivo. Il server "
        "sopravvive alla chiusura della console; altre console possono agganciarsi.",
    ),
    "stop": (
        "stop",
        "Arresta il runtime server.",
        "Arresta in modo controllato il runtime leggendo il PID. Funziona da "
        "qualsiasi console, non solo da quella che lo ha avviato.",
    ),
    "restart": ("restart", "Riavvia il runtime.", "Esegue stop seguito da start."),
    "status": (
        "status",
        "Stato sintetico del runtime.",
        "Mostra se il runtime e' attivo, uptime e indirizzo loopback.",
    ),
    "monitor": (
        "monitor",
        "Snapshot del carico in tempo reale.",
        "Stampa una fotografia delle metriche di carico: byte in/out, accessi "
        "concorrenti, dati letti/scritti, tempo di risposta medio e p95, req/s. "
        "Le metriche live sono sempre visibili nella barra in alto.",
    ),
    "hw": (
        "hw",
        "Snapshot dello sforzo hardware.",
        "Stampa CPU, RAM e I/O con barre colorate per soglia.",
    ),
    "op": (
        "op create <username> | op list",
        "Gestione account OP.",
        "create <username>: crea un OP con password temporanea (mostrata una volta, "
        "cambio obbligatorio al primo accesso). list: elenca gli OP provvisori.",
    ),
    "query": (
        "query <sql>",
        "Interrogazione admin (solo admin).",
        "Esegue un'interrogazione amministrativa. In questa fase il database e' in "
        "sviluppo: la query viene tracciata ma non eseguita.",
    ),
    "backup": (
        "backup | backup list | backup auto on|off | backup restore <nome>",
        "Backup manuale/automatico dei dati.",
        "Senza argomenti: backup manuale immediato. list: elenca gli archivi. "
        "auto on|off: attiva/disattiva il backup automatico. restore <nome>: ripristina.",
    ),
    "audit": ("audit [n]", "Mostra il log di audit.", "Ultime n voci del log append-only."),
    "cronologia": (
        "cronologia [n]",
        "Cronologia operazioni della console.",
        "Mostra le ultime n operazioni eseguite dalla console, ripristinate da disco "
        "(sopravvivono alla chiusura, anche imprevista). Scorri con PagSu/PagGiu.",
    ),
    "set": (
        "set | set <chiave> <valore>",
        "Impostazioni personalizzabili a caldo.",
        "Senza argomenti elenca le impostazioni correnti. Chiavi: backup-auto on|off, "
        "backup-interval <sec>, backup-retention <n>, soglia-cpu <pct>, soglia-ram <pct>. "
        "Le scelte sono persistite (config.json) e sopravvivono al riavvio del runtime.",
    ),
    "selftest": (
        "selftest [richieste]",
        "Genera carico sintetico locale.",
        "Invia N richieste concorrenti al runtime per esercitare e dimostrare i "
        "monitor (senza client reali i contatori resterebbero a zero).",
    ),
    "help": (
        "help [comando]",
        "Aiuto generale o sul singolo comando.",
        "Senza argomenti elenca i comandi; con un comando ne mostra l'aiuto esteso.",
    ),
    "clear": ("clear", "Pulisce la chat.", "Svuota l'area chat (la barra in alto resta)."),
    "exit": (
        "exit [--keep]",
        "Arresta il runtime ed esce.",
        "Arresta il runtime (se attivo) e poi chiude la console, garantendo che il "
        "server non resti orfano. Usa 'exit --keep' per uscire lasciando il runtime attivo.",
    ),
}
#! Alias accettati per alcuni comandi.
ALIAS = {
    "hardware": "hw",
    "load": "selftest",
    "cls": "clear",
    "quit": "exit",
    "q": "exit",
    "history": "cronologia",
    "config": "set",
    "impostazioni": "set",
}

#! Rampa di caratteri per la sparkline della rete (U+2581..U+2588).
_SPARK = "▁▂▃▄▅▆▇█"
#! Numero di campioni conservati per la sparkline della rete.
_CAMPIONI_NET = 26


def _num(dati: dict[str, object], chiave: str, default: float = 0.0) -> float:
    """! @brief Estrae un valore numerico da uno snapshot (dict[str, object]).

    Gli snapshot del runtime sono serializzati come dict[str, object]: questo
    helper effettua la conversione in modo type-safe (niente float(object)).

    @param dati Dizionario sorgente (es. snapshot metriche/hardware).
    @param chiave Chiave da leggere.
    @param default Valore restituito se la chiave manca o non e' numerica.
    @return Valore convertito in float.
    """
    valore = dati.get(chiave, default)
    if isinstance(valore, bool):
        return float(valore)
    if isinstance(valore, (int, float)):
        return float(valore)
    if isinstance(valore, str):
        try:
            return float(valore)
        except ValueError:
            return default
    return default


def _intero(dati: dict[str, object], chiave: str, default: int = 0) -> int:
    """! @brief Estrae un valore intero da uno snapshot (dict[str, object]).
    @param dati Dizionario sorgente.
    @param chiave Chiave da leggere.
    @param default Valore restituito se la chiave manca o non e' numerica.
    @return Valore convertito in int.
    """
    return int(_num(dati, chiave, float(default)))


def _formatta_byte(n: float) -> str:
    """! @brief Formatta un numero di byte in forma leggibile.
    @param n Quantita' di byte.
    @return Stringa con unita' (B, KB, MB, GB).
    """
    for unita in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024 or unita == "TB":
            return f"{n:.1f} {unita}"
        n /= 1024
    return f"{n:.1f} TB"


def _barra(valore: float, soglia: float, larghezza: int = 24) -> str:
    """! @brief Rende una barra testuale colorata in base alla soglia.
    @param valore Valore percentuale (0-100).
    @param soglia Soglia di allerta.
    @param larghezza Larghezza in caratteri della barra.
    @return Markup rich della barra con percentuale.
    """
    pieni = int(max(0.0, min(100.0, valore)) / 100 * larghezza)
    stile = colore_soglia(valore, soglia)
    return f"[{stile}]{'█' * pieni}{'░' * (larghezza - pieni)}[/] {valore:5.1f}%"


def _fmt_uptime(secondi: float) -> str:
    """! @brief Formatta un uptime in secondi come HH:MM:SS.
    @param secondi Durata in secondi.
    @return Stringa HH:MM:SS.
    """
    t = max(0, int(secondi))
    return f"{t // 3600:02d}:{(t % 3600) // 60:02d}:{t % 60:02d}"


class StatoTelemetria:
    """! @brief Stato condiviso delle metriche live mostrate nella barra in alto.

    Aggiornato dal campionatore in un thread dedicato e letto dalla vista a ogni
    ridisegno. I campi rispecchiano gli indicatori del design handoff.
    """

    def __init__(self) -> None:
        """! @brief Inizializza lo stato a valori neutri (runtime non attivo)."""
        self.in_esecuzione = False  #! runtime raggiungibile
        self.cpu = 0.0  #! CPU di sistema (%)
        self.ram_usata = 0.0  #! RAM usata (GiB)
        self.ram_totale = 0.0  #! RAM totale (GiB)
        self.io = 0.0  #! I/O disco (MB/s)
        self.giu = 0.0  #! rete in ingresso (KB/s)
        self.su = 0.0  #! rete in uscita (KB/s)
        self.thread = 0  #! numero di thread del runtime
        self.uptime_s = 0.0  #! uptime del runtime (s), azzerato al restart
        self.dispositivi = 0  #! dispositivi client collegati di recente (tempo reale)
        self.picco_dispositivi = 0  #! picco di dispositivi collegati simultaneamente
        self.storia_net = [0.0] * _CAMPIONI_NET  #! buffer per la sparkline rete
        #! Ultimo snapshot completo di /metriche (alimenta il pannello "Stato runtime").
        self.metriche: dict[str, object] = {}


class ConsoleOperativa:
    """! @brief Console interattiva a schermo intero per la gestione del runtime.

    Riproduce il design handoff come TUI prompt_toolkit: barra telemetria fissa,
    brand con mascotte e stato, box dei comandi e chat scrollabile con prompt.
    Delega le operazioni al @ref Supervisore (start/stop) e al
    @ref ClientControllo (metriche, hardware, OP, backup, query). Piu' istanze
    possono girare in parallelo su terminali diversi.
    """

    def __init__(self) -> None:
        """! @brief Inizializza console, client di controllo, vista e applicazione."""
        self._imp: Impostazioni = Impostazioni.carica()
        self._client = ClientControllo(self._imp.base_url, self._imp.admin_token)
        #! Client a timeout breve per il campionatore (non deve bloccare la UI).
        self._client_metriche = ClientControllo(
            self._imp.base_url, self._imp.admin_token, timeout=1.0
        )
        self._sup = Supervisore(self._imp)

        #! Console rich "in cattura": l'output dei comandi viene reso in ANSI e
        #! accodato alla chat come testo formattato.
        self._buf_rich = io.StringIO()
        self._con = Console(
            file=self._buf_rich,
            theme=TEMA,
            force_terminal=True,
            color_system="truecolor",
            width=70,
            highlight=False,
            soft_wrap=False,
        )

        #! Cronologia persistente delle operazioni (sopravvive a chiusure impreviste).
        self._cronologia = CronologiaConsole(self._imp.file_cronologia_console)

        self._stato = StatoTelemetria()
        self._righe: list[StyleAndTextTuples] = []  #! storico chat (persistente)
        self._scorrimento = 0  #! righe risalite dal fondo (0 = ancorato in basso)
        self._stop = threading.Event()
        self._pool = ThreadPoolExecutor(max_workers=1)  #! comandi in coda sequenziale
        self._app: Application[None] | None = None

        self._righe.append(
            [
                ("class:hint", "Digita "),
                ("class:hint.b", "help"),
                ("class:hint", " per l'elenco completo dei comandi."),
            ]
        )
        self._righe.append(
            [
                (
                    "class:log.muted",
                    "Scorri lo storico con PagSu/PagGiu, Maiusc+Frecce, Inizio/Fine.",
                ),
            ]
        )
        self._ripristina_cronologia()

    def _ripristina_cronologia(self) -> None:
        """! @brief Ricarica in chat le ultime operazioni salvate su disco.

        Soddisfa il requisito di conservazione: dopo una chiusura (anche
        imprevista), all'avvio la console mostra le ultime attivita' eseguite.

        @return Nessuno.
        """
        voci = self._cronologia.ultime(12)
        if not voci:
            return
        self._righe.append(
            [("class:log.muted", f"──── cronologia operazioni ripristinata ({len(voci)}) ────")]
        )
        for v in voci:
            self._righe.append(self._riga_operazione_storica(v))

    def _riga_operazione_storica(self, voce: dict[str, object]) -> StyleAndTextTuples:
        """! @brief Rende una voce di cronologia integrata con l'estetica delle barre.

        Le operazioni passate sono mostrate nello stesso flusso dei caricamenti
        live, con una mini-barra completata colorata per esito (ok/errore).

        @param voce Voce di cronologia (ts, comando, esito).
        @return Frammenti formattati della riga.
        """
        esito = str(voce.get("esito", ""))
        stile = "class:log.ok" if esito == "ok" else "class:log.err"
        if esito not in {"ok", "errore"}:
            stile = "class:log.muted"
        return [
            ("class:log.muted", f"{str(voce.get('ts', ''))[11:19]} "),
            ("class:prompt.name", "leaf"),
            ("class:prompt.gt", " > "),
            ("class:log", str(voce.get("comando", ""))),
            ("class:log.muted", "  "),
            (stile, "████"),
            ("class:log.muted", f" {esito}"),
        ]

    # ---- costruzione della vista -----------------------------------------

    def _crea_app(self) -> Application[None]:
        """! @brief Assembla layout, stile e key binding dell'applicazione.
        @return Istanza Application pronta per @ref esegui.
        """
        # Prompt con la foglia 🍃 esistente (NON la mascotte pixel) e cursore.
        self._input = Buffer(
            accept_handler=self._accetta,
            multiline=False,
            completer=WordCompleter(list(COMANDI) + list(ALIAS), ignore_case=True),
            complete_while_typing=False,
        )
        finestra_prompt = Window(
            BufferControl(self._input, focusable=True),
            height=1,
            get_line_prefix=self._prefisso_prompt,
            wrap_lines=False,
            style="class:prompt",
        )

        # Chat: storico scrollabile; il cursore (per lo scroll) segue il fondo.
        finestra_chat = Window(
            FormattedTextControl(
                self._testo_chat,
                focusable=False,
                show_cursor=False,
                get_cursor_position=self._posizione_chat,
            ),
            wrap_lines=True,
            style="class:log",
        )

        # Mascotte con lo stato subito sotto (requisito: stato sotto la mascotte).
        col_mascotte = HSplit(
            [
                Window(
                    FormattedTextControl(foglia_formattata),
                    height=ALTEZZA_MASCOTTE,
                    width=24,
                ),
                Window(FormattedTextControl(self._testo_stato), height=1, width=24),
            ]
        )
        # Accanto alla foglia: brand + benvenuto + server card (spostati qui per
        # liberare spazio verticale alla chat e rendere visibili le operazioni).
        col_brand = HSplit(
            [
                Window(height=1),
                Window(FormattedTextControl(self._testo_wordmark), height=1),
                Window(FormattedTextControl(self._testo_sottotitolo), height=1),
                Window(height=1),
                Window(FormattedTextControl([("class:hi", "Bentornato, admin!")]), height=1),
                Window(height=1),
                Window(FormattedTextControl(self._testo_card), height=3),
            ]
        )
        brand = VSplit([col_mascotte, Window(width=3), col_brand])

        # Colonna sinistra: brand (mascotte + testo affiancato) in alto, poi la chat
        # ampia col prompt: le operazioni eseguite restano ben visibili.
        col_sinistra = HSplit(
            [
                brand,
                Window(height=1, char="─", style="class:sep"),
                finestra_chat,
                finestra_prompt,
            ]
        )

        # Colonna destra: riquadri in ALTO (dimensionati al contenuto) e, SOTTO, il
        # pannello "Stato runtime" coi parametri del runtime; il riempitivo finale
        # spinge tutto verso l'alto.
        larghezza_box = Dimension(min=42, preferred=54)
        col_destra = HSplit(
            [
                Frame(
                    Window(
                        FormattedTextControl(self._testo_comandi),
                        width=larghezza_box,
                        dont_extend_height=True,
                    ),
                    title="Comandi principali",
                ),
                Frame(
                    Window(
                        FormattedTextControl(self._testo_suggerimenti),
                        width=larghezza_box,
                        dont_extend_height=True,
                    ),
                    title="Suggerimenti",
                ),
                Frame(
                    Window(
                        FormattedTextControl(self._testo_stato_runtime),
                        width=larghezza_box,
                        dont_extend_height=True,
                    ),
                    title="Stato runtime",
                ),
                Window(),
            ]
        )

        corpo = HSplit(
            [
                Window(
                    FormattedTextControl(self._testo_telemetria),
                    height=1,
                    wrap_lines=False,
                    style="class:monitor",
                ),
                Window(height=1, char="─", style="class:sep"),
                VSplit([col_sinistra, Window(width=3), col_destra]),
            ],
            style="class:base",
        )

        layout = Layout(Frame(corpo), focused_element=finestra_prompt)
        return Application(
            layout=layout,
            key_bindings=self._key_binding(),
            style=stile_tui(),
            full_screen=True,
            mouse_support=False,
            refresh_interval=0.5,
        )

    def _key_binding(self) -> KeyBindings:
        """! @brief Definisce uscita e scorrimento della chat.
        @return Set di key binding dell'applicazione.
        """
        kb = KeyBindings()

        @kb.add("c-c")
        @kb.add("c-d")
        def _(event: object) -> None:  # noqa: ANN401
            """! @brief Esce dalla console (il runtime resta attivo)."""
            assert self._app is not None
            self._app.exit()

        @kb.add("pageup")
        def _(event: object) -> None:  # noqa: ANN401
            """! @brief Risale di una pagina nello storico chat."""
            self._scorri(10)

        @kb.add("pagedown")
        def _(event: object) -> None:  # noqa: ANN401
            """! @brief Scende di una pagina nello storico chat."""
            self._scorri(-10)

        @kb.add("s-up")
        def _(event: object) -> None:  # noqa: ANN401
            """! @brief Risale di una riga nello storico chat."""
            self._scorri(1)

        @kb.add("s-down")
        def _(event: object) -> None:  # noqa: ANN401
            """! @brief Scende di una riga nello storico chat."""
            self._scorri(-1)

        @kb.add("home")
        def _(event: object) -> None:  # noqa: ANN401
            """! @brief Salta all'inizio dello storico chat."""
            self._scorri(len(self._righe))

        @kb.add("end")
        def _(event: object) -> None:  # noqa: ANN401
            """! @brief Torna in fondo allo storico chat (ultime operazioni)."""
            self._scorrimento = 0

        return kb

    def _scorri(self, passi: int) -> None:
        """! @brief Aggiorna lo scorrimento della chat entro i limiti dello storico.
        @param passi Righe da risalire (positivo) o scendere (negativo).
        @return Nessuno.
        """
        massimo = max(0, len(self._righe) - 1)
        self._scorrimento = max(0, min(massimo, self._scorrimento + passi))

    def _prefisso_prompt(self, numero_riga: int, conteggio_a_capo: int) -> StyleAndTextTuples:
        """! @brief Prefisso del prompt: foglia 🍃 esistente + "leaf >".
        @param numero_riga Indice di riga (ignorato, prompt monoriga).
        @param conteggio_a_capo Conteggio di a-capo (ignorato).
        @return Frammenti formattati del prefisso.
        """
        return [
            ("class:prompt.leaf", "\U0001f343 "),
            ("class:prompt.name", "leaf"),
            ("class:prompt.gt", " > "),
        ]

    # ---- testo formattato delle viste (lette a ogni ridisegno) -----------

    def _testo_chat(self) -> StyleAndTextTuples:
        """! @brief Costruisce il testo formattato dell'area chat (storico completo).
        @return Frammenti delle righe accodate, separate da a-capo.
        """
        out: StyleAndTextTuples = []
        for riga in self._righe:
            out.extend(riga)
            out.append(("", "\n"))
        if out:
            out.pop()  # rimuove l'ultimo a-capo
        return out

    def _posizione_chat(self) -> Point:
        """! @brief Posizione "cursore" della chat: pilota lo scorrimento verticale.

        Con scorrimento 0 punta all'ultima riga (la finestra resta ancorata in
        basso e mostra le ultime operazioni); risalendo, segue lo storico.

        @return Punto (colonna, riga) da mantenere visibile.
        """
        ultima = max(0, len(self._righe) - 1)
        return Point(x=0, y=max(0, ultima - self._scorrimento))

    def _testo_telemetria(self) -> StyleAndTextTuples:
        """! @brief Barra telemetria snella sempre visibile (carico hardware live).

        Tiene solo gli indicatori hardware in tempo reale (CPU/RAM/IO/NET) per
        non andare a capo; i parametri del runtime (dispositivi, thread, uptime,
        richieste...) vivono nel pannello "Stato runtime" sotto i riquadri.

        @return Frammenti formattati della barra.
        """
        s = self._stato
        pulse = "class:pulse.on" if s.in_esecuzione else "class:pulse.off"
        run = ("class:run.on", "attivo") if s.in_esecuzione else ("class:run.off", "fermo")
        ram_pct = (s.ram_usata / s.ram_totale * 100) if s.ram_totale else 0.0
        out: StyleAndTextTuples = [
            (pulse, "● "),
            ("class:lbl", "RUNTIME "),
            run,
            ("", "    "),
            ("class:lbl", "CPU "),
            *self._gauge(s.cpu),
            ("class:val", f" {s.cpu:.0f}%"),
            ("", "    "),
            ("class:lbl", "RAM "),
            *self._gauge(ram_pct),
            ("class:val", f" {s.ram_usata:.1f}/{s.ram_totale:.1f}G"),
            ("", "    "),
            ("class:lbl", "IO "),
            ("class:val.dim", f"{s.io:.1f} MB/s"),
            ("", "    "),
            ("class:lbl", "NET "),
            ("class:spark", self._sparkline(s.storia_net)),
            ("", " "),
            ("class:arrow.d", "↓"),
            ("class:val", f"{s.giu:.1f} "),
            ("class:arrow.u", "↑"),
            ("class:val", f"{s.su:.1f} KB/s"),
        ]
        return out

    def _testo_stato_runtime(self) -> StyleAndTextTuples:
        """! @brief Pannello "Stato runtime" sotto i riquadri: parametri del runtime.

        Raccoglie i parametri spostati dalla barra (dispositivi collegati, thread,
        uptime) e altri indicatori standard utili letti dall'ultimo snapshot di
        /metriche: richieste totali/errori, req/s, concorrenza, tempi di risposta,
        traffico applicativo. Aggiornato dal campionatore ogni secondo.

        @return Frammenti formattati del pannello (più righe).
        """
        s = self._stato
        m = s.metriche
        if not s.in_esecuzione:
            return [("class:log.muted", "runtime non attivo — avvia con "), ("class:cmd", "start")]
        attive = _intero(m, "richieste_attive")
        picco_conc = _intero(m, "picco_concorrenza")
        errori = _intero(m, "richieste_errore")
        righe: StyleAndTextTuples = [
            ("class:lbl", "Dispositivi  "),
            ("class:devices" if s.dispositivi else "class:val.dim", f"{s.dispositivi}"),
            ("class:val.dim", f"  picco {s.picco_dispositivi}\n"),
            ("class:lbl", "Thread       "),
            ("class:val", f"{s.thread}"),
            ("class:val.dim", "   "),
            ("class:lbl", "Uptime "),
            ("class:val", f"{_fmt_uptime(s.uptime_s)}\n"),
            ("class:lbl", "Richieste    "),
            ("class:val", f"{_intero(m, 'richieste_totali')}"),
            ("class:val.dim", f"  ({errori} errori)\n"),
            ("class:lbl", "Req/s        "),
            ("class:val", f"{_num(m, 'richieste_al_secondo'):.2f}"),
            ("class:val.dim", "   "),
            ("class:lbl", "Concorr. "),
            ("class:val", f"{attive}"),
            ("class:val.dim", f" (picco {picco_conc})\n"),
            ("class:lbl", "Risposta     "),
            ("class:val", f"{_num(m, 'tempo_risposta_medio_ms'):.1f}"),
            ("class:val.dim", " / "),
            ("class:val", f"{_num(m, 'tempo_risposta_p95_ms'):.1f}"),
            ("class:val.dim", " ms (med/p95)\n"),
            ("class:lbl", "Traffico     "),
            ("class:arrow.d", "↓"),
            ("class:val", f"{_formatta_byte(_num(m, 'byte_in'))} "),
            ("class:arrow.u", "↑"),
            ("class:val", f"{_formatta_byte(_num(m, 'byte_out'))}"),
        ]
        return righe

    def _gauge(self, pct: float, celle: int = 8) -> StyleAndTextTuples:
        """! @brief Costruisce un gauge a blocchi (pieni/vuoti) come nel design.
        @param pct Percentuale 0-100.
        @param celle Numero di celle del gauge.
        @return Frammenti formattati del gauge.
        """
        pieni = max(0, min(celle, round(pct / 100 * celle)))
        return [("class:gauge.f", "█" * pieni), ("class:gauge.e", "█" * (celle - pieni))]

    def _sparkline(self, storia: list[float]) -> str:
        """! @brief Costruisce la sparkline della rete riscalando sul proprio massimo.
        @param storia Campioni recenti (down+up).
        @return Stringa di caratteri sparkline.
        """
        massimo = max([1.0, *storia])
        return "".join(_SPARK[max(0, min(7, int(v / massimo * 7)))] for v in storia)

    def _testo_stato(self) -> StyleAndTextTuples:
        """! @brief Riga di stato sotto la mascotte, aggiornata col runtime.
        @return Frammenti formattati dello stato.
        """
        if self._stato.in_esecuzione:
            return [("class:pulse.on", "● "), ("class:run.on", "online")]
        return [("class:pulse.off", "● "), ("class:run.off", "non avviato")]

    def _testo_wordmark(self) -> StyleAndTextTuples:
        """! @brief Wordmark "LEAF MOBILITY".
        @return Frammenti formattati del wordmark.
        """
        return [("class:wordmark.leaf", "LEAF "), ("class:wordmark.mob", "MOBILITY")]

    def _testo_sottotitolo(self) -> StyleAndTextTuples:
        """! @brief Sottotitolo del brand con versione.
        @return Frammenti formattati del sottotitolo.
        """
        return [
            ("class:sub", "Console Operativa "),
            ("class:sub.v", "v0.1.0"),
            ("class:sub", " · runtime locale"),
        ]

    def _testo_card(self) -> StyleAndTextTuples:
        """! @brief Server card: server, endpoint e stato (live).
        @return Frammenti formattati della card.
        """
        endpoint = self._imp.base_url.split("://", 1)[-1]
        stato = self._testo_stato()
        accesso = (
            ("class:run.on", "rete (esterni)")
            if self._imp.esposto_in_rete
            else ("class:val", "loopback")
        )
        return [
            ("class:card.k", "endpoint "),
            ("class:card.link", f"{endpoint}\n"),
            ("class:card.k", "api      "),
            ("class:card.v", "/api/v1 · "),
            *(accesso,),
            ("class:card.v", "\n"),
            ("class:card.k", "stato    "),
            *stato,
        ]

    def _testo_comandi(self) -> StyleAndTextTuples:
        """! @brief Contenuto del box "Comandi principali".
        @return Frammenti formattati del box.
        """
        return [
            ("class:cmd", "start / stop  "),
            ("class:desc", "avvia o arresta il runtime\n"),
            ("class:cmd", "monitor       "),
            ("class:desc", "carico in tempo reale\n"),
            ("class:cmd", "hw            "),
            ("class:desc", "sforzo hardware (CPU/RAM/IO)\n"),
            ("class:cmd", "op create "),
            ("class:arg", "<u> "),
            ("class:desc", "nuovo OP con password temporanea\n"),
            ("class:cmd", "backup        "),
            ("class:desc", "backup manuale / automatico"),
        ]

    def _testo_suggerimenti(self) -> StyleAndTextTuples:
        """! @brief Contenuto del box "Suggerimenti".
        @return Frammenti formattati del box.
        """
        return [
            ("class:cmd", "set           "),
            ("class:desc", "impostazioni (es. intervallo backup)\n"),
            ("class:cmd", "cronologia    "),
            ("class:desc", "ultime operazioni (anche dopo riavvio)\n"),
            ("class:cmd", "audit         "),
            ("class:desc", "log append-only delle azioni\n"),
            ("class:cmd", "help "),
            ("class:arg", "<comando> "),
            ("class:desc", "aiuto sul singolo comando\n"),
            ("class:cmd", "exit          "),
            ("class:desc", "arresta il runtime ed esce"),
        ]

    # ---- chat: scrittura e cattura output rich ---------------------------

    def _aggiorna_ui(self, operazione: Callable[[], None]) -> None:
        """! @brief Esegue un'operazione sul thread della UI in modo sicuro.
        @param operazione Callback da eseguire.
        @return Nessuno.
        """
        if self._app is not None and self._app.loop is not None:
            self._app.loop.call_soon_threadsafe(operazione)
        else:
            operazione()

    def _scrivi(self, frammenti: StyleAndTextTuples) -> None:
        """! @brief Accoda una riga formattata alla chat e ancora la vista al fondo.
        @param frammenti Frammenti (classe_stile, testo) della riga.
        @return Nessuno.
        """

        def op() -> None:
            self._righe.append(frammenti)
            self._scorrimento = 0
            self._invalida()

        self._aggiorna_ui(op)

    def _scrivi_testo(self, testo: str, classe: str = "log") -> None:
        """! @brief Accoda una riga di testo semplice con una classe di stile.
        @param testo Contenuto della riga.
        @param classe Classe di stile (es. "log.ok").
        @return Nessuno.
        """
        self._scrivi([(f"class:{classe}", testo)])

    def _eco(self, riga: str) -> None:
        """! @brief Riporta in chat il comando digitato (come nel prototipo).
        @param riga Testo del comando.
        @return Nessuno.
        """
        self._scrivi(
            [
                ("class:prompt.name", "leaf"),
                ("class:prompt.gt", " > "),
                ("class:log.muted", riga),
            ]
        )

    def _barra_caricamento(
        self, descrizione: str, passi: list[str], durata_passo: float = 0.22
    ) -> None:
        """! @brief Mostra i passi di un'operazione, uno per riga, con percentuale.

        Ogni sotto-passo intermedio resta **visibile** come riga a sé (marcatore
        "▸ <passo>") con la barra e la percentuale di completamento cumulata: si
        vede l'operazione in corso, l'avanzamento e — a cura del chiamante — il
        messaggio finale "operazione avviata".

        @param descrizione Etichetta generale dell'operazione (intestazione).
        @param passi Sotto-passi; ognuno aggiunge una riga e avanza la percentuale.
        @param durata_passo Pausa tra un passo e il successivo (secondi).
        @return Nessuno.
        """
        larghezza = 16

        def init_op() -> None:
            self._righe.append([("class:log.head", f"{descrizione}…")])
            self._righe.append([("class:log.muted", "▸ ")])
            self._scorrimento = 0
            self._invalida()

        self._aggiorna_ui(init_op)

        totale = max(1, len(passi))
        for i, passo in enumerate(passi, start=1):
            frazione = i / totale
            pieni = int(frazione * larghezza)

            def update_op(
                idx: int = i, p: str = passo, f: float = frazione, fp: int = pieni
            ) -> None:
                indice = len(self._righe) - 1
                self._righe[indice] = [
                    ("class:log.muted", "▸ "),
                    ("class:log", f"{p:<26}"),
                    ("class:gauge.f", "█" * fp),
                    ("class:gauge.e", "█" * (larghezza - fp)),
                    ("class:val", f" {f * 100:3.0f}%"),
                ]
                self._scorrimento = 0
                if idx < totale:
                    self._righe.append([("class:log.muted", "▸ ")])
                self._invalida()

            self._aggiorna_ui(update_op)
            time.sleep(durata_passo)

    def _svuota_rich(self) -> None:
        """! @brief Travasa l'output rich accumulato nella chat (una riga per riga).
        @return Nessuno.
        """
        testo = self._buf_rich.getvalue()
        self._buf_rich.seek(0)
        self._buf_rich.truncate(0)
        if not testo:
            return

        def op() -> None:
            for riga in testo.rstrip("\n").split("\n"):
                self._righe.append(to_formatted_text(ANSI(riga)))
            self._scorrimento = 0
            self._invalida()

        self._aggiorna_ui(op)

    def _invalida(self) -> None:
        """! @brief Richiede un ridisegno dell'applicazione (thread-safe).
        @return Nessuno.
        """
        if self._app is not None:
            self._app.invalidate()

    # ---- ciclo principale -------------------------------------------------

    def esegui(self) -> None:
        """! @brief Avvia la TUI a schermo intero finche' l'utente non esce.
        @return Nessuno.
        """
        self._stato.in_esecuzione = self._client.raggiungibile()
        self._app = self._crea_app()
        th = threading.Thread(target=self._ciclo_campionatore, daemon=True)
        th.start()
        try:
            self._app.run()
        finally:
            self._stop.set()
            self._pool.shutdown(wait=False)

    def _ciclo_campionatore(self) -> None:
        """! @brief Campiona ogni secondo metriche locali e stato/uptime del runtime.

        CPU, RAM, I/O disco e rete sono lette localmente con psutil (sempre
        disponibili); stato, thread e uptime provengono dal runtime quando attivo.
        L'uptime e' quello del processo runtime: si azzera a ogni restart.

        @return Nessuno.
        """
        psutil.cpu_percent(None)  # innesco (la prima lettura vale 0)
        net0 = psutil.net_io_counters()
        disco0 = psutil.disk_io_counters()
        t0 = time.monotonic()
        while not self._stop.wait(1.0):
            ora = time.monotonic()
            dt = max(1e-3, ora - t0)
            t0 = ora
            s = self._stato
            s.cpu = psutil.cpu_percent(None)
            vm = psutil.virtual_memory()
            s.ram_usata = vm.used / 2**30
            s.ram_totale = vm.total / 2**30
            net = psutil.net_io_counters()
            s.giu = max(0.0, (net.bytes_recv - net0.bytes_recv) / dt / 1024)
            s.su = max(0.0, (net.bytes_sent - net0.bytes_sent) / dt / 1024)
            net0 = net
            disco = psutil.disk_io_counters()
            if disco is not None and disco0 is not None:
                attuale = disco.read_bytes + disco.write_bytes
                precedente = disco0.read_bytes + disco0.write_bytes
                s.io = max(0.0, (attuale - precedente) / dt / 2**20)
                disco0 = disco
            s.storia_net = [*s.storia_net[1:], s.giu + s.su]
            # Stato / uptime / thread / dispositivi dal runtime (timeout breve).
            try:
                snap = self._client_metriche.metriche()
                s.in_esecuzione = True
                s.metriche = snap
                s.uptime_s = _num(snap, "uptime_s")
                s.dispositivi = _intero(snap, "dispositivi_collegati")
                s.picco_dispositivi = _intero(snap, "picco_dispositivi")
                with contextlib.suppress(ErroreControllo):
                    s.thread = _intero(self._client_metriche.hardware(), "thread", s.thread)
            except ErroreControllo:
                s.in_esecuzione = False
                s.uptime_s = 0.0
                s.thread = 0
                s.dispositivi = 0
                s.metriche = {}
            self._invalida()

    def _accetta(self, buff: Buffer) -> bool:
        """! @brief Gestore Invio del prompt: interpreta o accoda il comando.

        clear/exit sono gestiti sul thread della UI (azione immediata); gli altri
        comandi vengono eseguiti in un thread dedicato per non bloccare la vista.

        @param buff Buffer del prompt.
        @return False per svuotare il prompt dopo l'invio.
        """
        riga = buff.text
        testo = riga.strip()
        if not testo:
            return False
        token = testo.split()
        nome = ALIAS.get(token[0].lower(), token[0].lower())
        if nome == "exit":
            self._eco(riga)
            mantieni = any(a in {"--keep", "keep"} for a in token[1:])
            self._cronologia.aggiungi(riga, "uscita")
            if mantieni or not self._sup.in_esecuzione():
                if not mantieni:
                    self._scrivi_testo("runtime non attivo: chiusura console.", "log.muted")
                else:
                    self._scrivi_testo("uscita: il runtime resta attivo (--keep).", "log.muted")
                self._pianifica_uscita()
            else:
                self._pool.submit(self._esegui_uscita)
            return False
        self._eco(riga)
        if nome == "clear":
            self._righe.clear()
            self._scorrimento = 0
            self._cronologia.aggiungi(riga, "ok")
            self._invalida()
            return False
        self._pool.submit(self._esegui_comando, riga)
        return False

    def _pianifica_uscita(self) -> None:
        """! @brief Richiede la chiusura della TUI in modo thread-safe.
        @return Nessuno.
        """
        app = self._app
        if app is None:
            return
        if app.loop is not None:
            app.loop.call_soon_threadsafe(app.exit)
        else:
            app.exit()

    def _esegui_uscita(self) -> None:
        """! @brief Arresta il runtime (se attivo) e poi chiude la console.

        Soddisfa il requisito: digitando `exit` la console si assicura prima di
        chiudere il server, evitando di lasciarlo orfano. Eseguito in un thread
        dedicato per non bloccare la vista durante l'arresto.

        @return Nessuno.
        """
        self._barra_caricamento(
            "Arresto runtime",
            ["Drenaggio richieste", "Stop servizi", "Chiusura processo", "Fatto"],
        )
        if self._sup.arresta():
            self._stato.in_esecuzione = False
            self._scrivi_testo("runtime arrestato. chiusura console.", "log.ok")
        else:
            self._scrivi_testo("arresto non confermato: chiusura console comunque.", "log.warn")
        time.sleep(0.4)
        self._pianifica_uscita()

    def _esegui_comando(self, riga: str) -> None:
        """! @brief Esegue un comando in background e travasa l'output in chat.
        @param riga Testo del comando.
        @return Nessuno.
        """
        esito = "ok"
        try:
            self._dispatch(riga)
        except ErroreControllo as exc:
            esito = "errore"
            self._scrivi_testo(f"Errore runtime: {exc}", "log.err")
        except Exception as exc:  # noqa: BLE001 — la console non deve mai crashare
            esito = "errore"
            self._scrivi_testo(f"Errore: {exc}", "log.err")
        finally:
            self._svuota_rich()
            self._cronologia.aggiungi(riga, esito)

    def _dispatch(self, riga: str) -> None:
        """! @brief Interpreta ed esegue una riga di comando.
        @param riga Testo immesso dall'utente.
        @return Nessuno.
        """
        try:
            token = shlex.split(riga)
        except ValueError as exc:
            self._scrivi_testo(f"Sintassi non valida: {exc}", "log.err")
            return
        nome = ALIAS.get(token[0].lower(), token[0].lower())
        args = token[1:]
        gestori = {
            "start": self._cmd_start,
            "stop": self._cmd_stop,
            "restart": self._cmd_restart,
            "status": self._cmd_status,
            "monitor": self._cmd_monitor,
            "hw": self._cmd_hw,
            "op": self._cmd_op,
            "query": self._cmd_query,
            "backup": self._cmd_backup,
            "audit": self._cmd_audit,
            "cronologia": self._cmd_cronologia,
            "set": self._cmd_set,
            "selftest": self._cmd_selftest,
            "help": self._cmd_help,
        }
        gestore = gestori.get(nome)
        if gestore is None:
            self._scrivi(
                [
                    ("class:log.err", "comando non riconosciuto: "),
                    ("class:log.b", nome),
                    ("class:log.err", " — digita "),
                    ("class:log.b", "help"),
                ]
            )
            return
        gestore(args)

    # ---- comandi ----------------------------------------------------------

    def _cmd_help(self, args: list[str]) -> None:
        """! @brief Mostra l'aiuto generale o di un singolo comando.
        @param args Eventuale nome di comando di cui mostrare l'aiuto esteso.
        @return Nessuno.
        """
        if args:
            nome = ALIAS.get(args[0].lower(), args[0].lower())
            meta = COMANDI.get(nome)
            if not meta:
                self._con.print(f"[err]Nessun aiuto per:[/] {args[0]}")
                return
            sintassi, _, lungo = meta
            self._con.print(f"[cmd]{sintassi}[/]\n{lungo}")
            return
        self._scrivi([("class:log.head", "comandi disponibili")])
        for nome, (_, breve, _lungo) in COMANDI.items():
            self._scrivi([("class:log.b", f"  {nome:<10}"), ("class:desc", breve)])
        self._scrivi(
            [
                ("class:log.muted", "  Dettagli: "),
                ("class:log.b", "help <comando>"),
            ]
        )

    def _cmd_start(self, args: list[str]) -> None:
        """! @brief Avvia il runtime mostrando i passi di caricamento in chat.
        @param args Ignorati.
        @return Nessuno.
        """
        if self._sup.in_esecuzione():
            self._scrivi_testo("runtime gia' attivo.", "log.muted")
            return
        self._barra_caricamento(
            "Avvio runtime",
            [
                "Verifica ambiente",
                "Bind loopback",
                "Strumentazione metriche",
                "Servizi runtime",
                "Pronto",
            ],
        )
        if self._sup.avvia():
            self._stato.in_esecuzione = True
            self._con.print(f"[ok]Runtime avviato[/] su [info]{self._imp.base_url}[/].")
            self._con.print("[log.muted]Verifica tunnel Cloudflare…[/]")
            url_tunnel = self._sup.avvia_tunnel()
            if self._sup.tunnel_attivo:
                self._con.print(f"[ok]Tunnel Cloudflare attivo[/] → [info]{url_tunnel}[/]")
            else:
                self._con.print(
                    f"[warn]Servizio cloudflared non rilevato, URL atteso:[/] [info]{url_tunnel}[/]"
                )
        else:
            self._con.print("[err]Avvio non riuscito.[/] Vedi server/dati/server.log.")

    def _cmd_stop(self, args: list[str]) -> None:
        """! @brief Arresta il runtime.
        @param args Ignorati.
        @return Nessuno.
        """
        if not self._sup.in_esecuzione():
            self._scrivi_testo("runtime non attivo.", "log.muted")
            return
        if self._sup.arresta():
            self._stato.in_esecuzione = False
            self._con.print("[warn]runtime arrestato. stato: non avviato.[/]")
        else:
            self._con.print("[err]Arresto fallito.[/]")

    def _cmd_restart(self, args: list[str]) -> None:
        """! @brief Riavvia il runtime (azzera l'uptime mostrato in barra).
        @param args Ignorati.
        @return Nessuno.
        """
        self._sup.arresta()
        self._stato.in_esecuzione = False
        self._stato.uptime_s = 0.0
        time.sleep(0.5)
        self._cmd_start(args)

    def _cmd_status(self, args: list[str]) -> None:
        """! @brief Mostra lo stato sintetico del runtime.
        @param args Ignorati.
        @return Nessuno.
        """
        if not self._client.raggiungibile():
            self._con.print("[warn]Runtime non attivo.[/] Usa [cmd]start[/].")
            return
        snap = self._client.metriche()
        self._con.print(
            f"server [val]runtime locale[/] · endpoint [val]{self._imp.base_url}[/] · "
            f"uptime [val]{_fmt_uptime(_num(snap, 'uptime_s'))}[/] · dispositivi "
            f"[val]{_intero(snap, 'dispositivi_collegati')}[/] · richieste totali "
            f"[val]{_intero(snap, 'richieste_totali')}[/]."
        )

    def _richiede_runtime(self) -> bool:
        """! @brief Verifica che il runtime sia attivo, altrimenti avvisa in chat.
        @return True se attivo, False altrimenti (con messaggio).
        """
        if self._client.raggiungibile():
            return True
        self._con.print("[warn]Runtime non attivo.[/] Avvialo con [cmd]start[/].")
        return False

    def _cmd_monitor(self, args: list[str]) -> None:
        """! @brief Stampa uno snapshot delle metriche di carico in chat.
        @param args Ignorati (le metriche live sono nella barra in alto).
        @return Nessuno.
        """
        if not self._richiede_runtime():
            return
        snap = self._client.metriche()
        t = Table(title="Carico runtime", title_style="head", border_style="verde")
        t.add_column("Metrica", style="head")
        t.add_column("Valore", style="val", justify="right")
        t.add_row("Uptime", _fmt_uptime(_num(snap, "uptime_s")))
        dispositivi = _intero(snap, "dispositivi_collegati")
        picco_disp = _intero(snap, "picco_dispositivi")
        t.add_row("Dispositivi collegati", f"{dispositivi} (picco {picco_disp})")
        t.add_row(
            "Accessi concorrenti",
            f"{_intero(snap, 'richieste_attive')} (picco {_intero(snap, 'picco_concorrenza')})",
        )
        t.add_row(
            "Richieste totali",
            f"{_intero(snap, 'richieste_totali')} ({_intero(snap, 'richieste_errore')} errori)",
        )
        t.add_row("Richieste/sec", str(snap["richieste_al_secondo"]))
        t.add_row("Byte in entrata", _formatta_byte(_num(snap, "byte_in")))
        t.add_row("Byte in uscita", _formatta_byte(_num(snap, "byte_out")))
        t.add_row("Dati letti", _formatta_byte(_num(snap, "dati_letti")))
        t.add_row("Dati scritti", _formatta_byte(_num(snap, "dati_scritti")))
        t.add_row("Tempo risposta medio", f"{snap['tempo_risposta_medio_ms']} ms")
        t.add_row("Tempo risposta p95", f"{snap['tempo_risposta_p95_ms']} ms")
        self._con.print(t)

    def _cmd_hw(self, args: list[str]) -> None:
        """! @brief Stampa uno snapshot dello sforzo hardware con barre colorate.
        @param args Ignorati (i valori live sono nella barra in alto).
        @return Nessuno.
        """
        if not self._richiede_runtime():
            return
        hw = self._client.hardware()
        t = Table(title="Sforzo hardware", title_style="head", border_style="verde")
        t.add_column("Risorsa", style="head")
        t.add_column("Stato", style="val")
        soglia_cpu, soglia_ram = _num(hw, "soglia_cpu"), _num(hw, "soglia_ram")
        t.add_row("CPU processo", _barra(_num(hw, "cpu_processo_pct"), soglia_cpu, 16))
        t.add_row("CPU sistema", _barra(_num(hw, "cpu_sistema_pct"), soglia_cpu, 16))
        t.add_row("RAM sistema", _barra(_num(hw, "ram_sistema_pct"), soglia_ram, 16))
        t.add_row("RAM processo", f"{hw['ram_processo_mb']} MB")
        t.add_row("I/O disco", f"R {hw['disco_letti_mb']} MB · W {hw['disco_scritti_mb']} MB")
        t.add_row("I/O rete", f"↑ {hw['rete_inviati_mb']} MB · ↓ {hw['rete_ricevuti_mb']} MB")
        t.add_row("Thread / PID", f"{hw['thread']} / {hw['pid']}")
        self._con.print(t)

    def _cmd_op(self, args: list[str]) -> None:
        """! @brief Gestione account OP: create/list.
        @param args Sottocomando ("create <username>" oppure "list").
        @return Nessuno.
        """
        if not self._richiede_runtime():
            return
        if args and args[0] == "create" and len(args) >= 2:
            esito = self._client.crea_op(args[1])
            self._con.print(f"[ok]OP creato:[/] [val]{esito['username']}[/]")
            self._con.print(
                f"Password temporanea (mostrata una sola volta): "
                f"[leaf]{esito['password_temporanea']}[/]"
            )
            self._con.print("[dim]L'OP dovra' cambiarla al primo accesso (IIN-12).[/]")
        elif args and args[0] == "list":
            righe = self._client.elenco_op()
            if not righe:
                self._con.print("[dim]Nessun OP provvisorio.[/]")
                return
            t = Table(title="Operatori (provvisori)", title_style="head", border_style="verde")
            t.add_column("Username", style="cmd")
            t.add_column("Creato il", style="val")
            t.add_column("Cambio pwd", style="val")
            for r in righe:
                t.add_row(
                    str(r["username"]),
                    str(r.get("creato_il", "—")),
                    "si" if r.get("deve_cambiare_password") else "no",
                )
            self._con.print(t)
        else:
            self._con.print("[warn]Uso:[/] op create <username> | op list")

    def _cmd_query(self, args: list[str]) -> None:
        """! @brief Esegue un'interrogazione amministrativa (solo admin).
        @param args Token che compongono l'istruzione SQL.
        @return Nessuno.
        """
        if not args:
            self._con.print("[warn]Uso:[/] query <sql>")
            return
        if not self._richiede_runtime():
            return
        esito = self._client.query(" ".join(args))
        self._con.print(f"[warn]{esito['messaggio']}[/]")

    def _cmd_backup(self, args: list[str]) -> None:
        """! @brief Gestione backup: manuale, list, auto on|off, restore.
        @param args Sottocomando opzionale.
        @return Nessuno.
        """
        if not self._richiede_runtime():
            return
        if not args:
            self._barra_caricamento(
                "Backup in corso", ["Raccolta dati", "Compressione", "Retention", "Completato"]
            )
            self._svuota_rich()
            meta = self._client.backup_manuale()
            self._con.print(
                f"[ok]Backup creato:[/] [val]{meta['nome']}[/] "
                f"({_formatta_byte(_num(meta, 'byte'))}, {meta['file']} file)"
            )
        elif args[0] == "list":
            dati = self._client.elenco_backup()
            archivi = cast("list[dict[str, object]]", dati.get("archivi", []))
            stato_auto = "ON" if dati.get("auto_attivo") else "OFF"
            self._con.print(f"Backup automatico: [val]{stato_auto}[/]")
            if not archivi:
                self._con.print("[dim]Nessun archivio.[/]")
                return
            t = Table(title="Archivi di backup", title_style="head", border_style="verde")
            t.add_column("Nome", style="cmd")
            t.add_column("Dimensione", style="val", justify="right")
            for a in archivi:
                t.add_row(str(a["nome"]), _formatta_byte(_num(a, "byte")))
            self._con.print(t)
        elif args[0] == "auto" and len(args) >= 2:
            attivo = args[1].lower() in {"on", "si", "true", "1"}
            self._client.backup_auto(attivo)
            self._con.print(f"[ok]Backup automatico:[/] {'ON' if attivo else 'OFF'}")
        elif args[0] == "restore" and len(args) >= 2:
            meta = self._client.backup_restore(args[1])
            self._con.print(f"[ok]Ripristinato:[/] {meta['file_ripristinati']} file da {args[1]}")
        else:
            self._con.print(
                "[warn]Uso:[/] backup | backup list | backup auto on|off | backup restore <nome>"
            )

    def _cmd_audit(self, args: list[str]) -> None:
        """! @brief Mostra le ultime voci del log di audit.
        @param args Numero opzionale di voci.
        @return Nessuno.
        """
        if not self._richiede_runtime():
            return
        n = int(args[0]) if args else 20
        voci = self._client.audit(n)
        if not voci:
            self._con.print("[dim]Audit vuoto.[/]")
            return
        t = Table(title="Audit log", title_style="head", border_style="verde")
        t.add_column("Timestamp", style="dim")
        t.add_column("Azione", style="cmd")
        t.add_column("Esito", style="val")
        for v in voci:
            t.add_row(str(v.get("ts", "")), str(v.get("azione", "")), str(v.get("esito", "")))
        self._con.print(t)

    def _cmd_cronologia(self, args: list[str]) -> None:
        """! @brief Mostra le ultime operazioni eseguite dalla console (persistenti).
        @param args Numero opzionale di voci (default 20).
        @return Nessuno.
        """
        n = int(args[0]) if args and args[0].isdigit() else 20
        voci = self._cronologia.ultime(n)
        if not voci:
            self._con.print("[dim]Nessuna operazione registrata.[/]")
            return
        t = Table(title="Cronologia operazioni console", title_style="head", border_style="verde")
        t.add_column("Quando", style="dim")
        t.add_column("Comando", style="cmd")
        t.add_column("Esito", style="val")
        for v in voci:
            quando = str(v.get("ts", "")).replace("T", " ")[:19]
            t.add_row(quando, str(v.get("comando", "")), str(v.get("esito", "")))
        self._con.print(t)

    #! Mappa chiave-da-console -> (campo config, convertitore) per il comando set.
    _CHIAVI_SET: dict[str, tuple[str, str]] = {
        "backup-auto": ("backup_auto", "bool"),
        "backup-interval": ("backup_intervallo_s", "int"),
        "backup-retention": ("backup_retention", "int"),
        "soglia-cpu": ("soglia_cpu", "float"),
        "soglia-ram": ("soglia_ram", "float"),
    }

    def _cmd_set(self, args: list[str]) -> None:
        """! @brief Mostra o modifica a caldo le impostazioni personalizzabili.
        @param args "<chiave> <valore>" per modificare; vuoto per elencare.
        @return Nessuno.
        """
        if not self._richiede_runtime():
            return
        if not args:
            self._mostra_config(self._client.config())
            return
        chiave = args[0].lower()
        meta = self._CHIAVI_SET.get(chiave)
        if meta is None:
            self._con.print(
                f"[warn]Chiave sconosciuta:[/] {chiave}. Disponibili: {', '.join(self._CHIAVI_SET)}"
            )
            return
        if len(args) < 2:
            self._con.print(f"[warn]Uso:[/] set {chiave} <valore>")
            return
        campo, tipo = meta
        try:
            valore = self._converti_valore(tipo, args[1])
        except ValueError:
            self._con.print(f"[err]Valore non valido per {chiave}:[/] {args[1]}")
            return
        cfg = self._client.aggiorna_config({campo: valore})
        self._con.print(f"[ok]Impostazione aggiornata:[/] {chiave} = [val]{valore}[/]")
        self._mostra_config(cfg)

    @staticmethod
    def _converti_valore(tipo: str, grezzo: str) -> object:
        """! @brief Converte il valore testuale di `set` nel tipo atteso.
        @param tipo Tipo target ("bool", "int", "float").
        @param grezzo Valore testuale immesso.
        @return Valore convertito.
        @throws ValueError Se la conversione fallisce.
        """
        if tipo == "bool":
            return grezzo.lower() in {"on", "si", "true", "1", "yes"}
        if tipo == "int":
            return int(grezzo)
        return float(grezzo)

    def _mostra_config(self, cfg: dict[str, object]) -> None:
        """! @brief Stampa le impostazioni personalizzabili correnti in tabella.
        @param cfg Configurazione restituita dal runtime.
        @return Nessuno.
        """
        t = Table(title="Impostazioni runtime", title_style="head", border_style="verde")
        t.add_column("Impostazione", style="head")
        t.add_column("Valore", style="val", justify="right")
        t.add_column("Comando", style="dim")
        t.add_row(
            "Backup automatico",
            "ON" if cfg.get("backup_auto") else "OFF",
            "set backup-auto on|off",
        )
        t.add_row(
            "Intervallo backup auto",
            f"{_intero(cfg, 'backup_intervallo_s')} s",
            "set backup-interval <sec>",
        )
        t.add_row(
            "Retention backup",
            f"{_intero(cfg, 'backup_retention')} archivi",
            "set backup-retention <n>",
        )
        t.add_row("Soglia allerta CPU", f"{_num(cfg, 'soglia_cpu'):.0f}%", "set soglia-cpu <pct>")
        t.add_row("Soglia allerta RAM", f"{_num(cfg, 'soglia_ram'):.0f}%", "set soglia-ram <pct>")
        self._con.print(t)

    def _cmd_selftest(self, args: list[str]) -> None:
        """! @brief Genera carico sintetico concorrente per esercitare i monitor.
        @param args Numero di richieste opzionale (default 200).
        @return Nessuno.
        """
        if not self._richiede_runtime():
            return
        totale = int(args[0]) if args else 200
        self._con.print(f"[info]Invio {totale} richieste concorrenti...[/]")
        self._svuota_rich()
        client = ClientControllo(self._imp.base_url, self._imp.admin_token, timeout=10)

        def colpo(_: int) -> None:
            """! @brief Singola richiesta del carico sintetico."""
            client.metriche()

        inizio = time.monotonic()
        with ThreadPoolExecutor(max_workers=32) as pool:
            list(pool.map(colpo, range(totale)))
        durata = time.monotonic() - inizio
        self._con.print(
            f"[ok]Completato[/] in {durata:.2f}s "
            f"(~{totale / durata:.0f} req/s). Usa [cmd]monitor[/] per i numeri."
        )
