---
tipo: fonte
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [itps, uml, classi, oggetti, relazioni, corso]
fonti: [raw/08.3_ITPS_UML_Classi_e_Oggetti_2026.pptx.pdf]
---

# ITPS — UML: Classi e Oggetti

Slide del corso **ITPS A.A. 2025/2026** (Barletta · Caivano · Piccinno), 78 slide — la fonte più estesa del blocco. Riferimenti: Sommerville cap. 7; Fowler capp. 3 e 5. Pagina concetto: → [[diagramma-delle-classi]].

## Contenuti chiave

- **Classe / Oggetto:** la classe è un «formato di oggetti»; l'oggetto è un'istanza che incapsula stato e comportamento e comunica via **messaggi** (segnatura: nome + tipi parametri + valore restituito).
- **Classi di analisi:** astrazioni del dominio del problema; formato minimale = nome + attributi + operazioni (responsabilità ad alto livello). Diagramma degli oggetti = istantanea del diagramma delle classi.
- **Qualità di una classe di analisi:** nome che ne rispecchia l'intento, astrazione ben definita, **3–5 responsabilità**, massima coesione, minima interdipendenza.
- **Verifiche (anti-pattern):** nessuna classe isolata; evitare proliferazione di classi semplici; evitare poche classi troppo complesse; evitare classi-funzione procedurali; **evitare le "classi onnipotenti"** (attenzione ai nomi con «sistema»/«controllore»); evitare alberi di ereditarietà profondi. Tecniche di rimedio: **fusione, separazione**, combinazione.
- **Individuazione delle classi:** dall'analisi testuale di problemi/bisogni/casi d'uso/glossario — nomi e predicati nominali → classi/attributi; verbi e frasi verbali → responsabilità.
- **Notazione:** tre scomparti (nome / attributi / operazioni); visibilità `+` public, `-` private, `#` protected, `~` package; segnatura `visibilità nome(par:tipo):tipoRestituito`. Corrispondenza diretta UML ↔ codice OO.
- **Relazioni:** associazione (bidirezionale, con nome/ruoli/**molteplicità**/navigabilità), aggregazione (whole-part, "parte-di"), composizione (parti senza vita propria, il tutto le crea/distrugge), **classe associativa** (proprietà della relazione, tipica di molti-a-molti), generalizzazione (ereditarietà, sostituibilità), dipendenza («usa»). Tutte con esempi di implementazione Java.

## Collegamenti al progetto

- Lente per il **diagramma delle classi** del progetto e per il disallineamento **TD-11** (class diagram ↔ codice). Vedi mappatura in → [[diagramma-delle-classi]].
- L'anti-pattern «classi onnipotenti con nome sistema/controllore» è uno spunto d'orale per giustificare i `Gestore*` come componenti di tier, non god-class.

## Pagine collegate

- [[diagramma-delle-classi]] · [[uml]] · [[diagramma-dei-componenti]]
- [[principi-ingegneria-software]] · [[leaf-mobility]]
