---
tipo: fonte
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [itps, principi, stream-coding, modularita, corso]
fonti: [raw/03_ITPS_Principi_Ingegneria_Software_2026.pptx.pdf]
---

# ITPS — Principi dell'Ingegneria del Software

Slide del corso **ITPS A.A. 2025/2026** (Barletta · Caivano · Piccinno), 52 slide. Riferimento: Ghezzi, Jazayeri, Mandrioli, cap. 3. Espone i **7 principi fondamentali** e, nelle slide finali (44–52), il loro adattamento allo **Stream Coding** (sviluppo assistito da AI).

## I 7 principi

1. **Rigore e Formalità** — sistematicità a complemento della creatività; la formalità (formalismi matematici) è il grado massimo di rigore.
2. **Separazione degli Interessi** — separare le decisioni per tempo, caratteristiche, prospettive, parti (interfaccia / regole di dominio / dati persistenti).
3. **Modularità** — alta coesione interna + basso accoppiamento, garantiti dall'**information hiding**; approcci Top-Down / Bottom-Up.
4. **Anticipazione del Cambiamento** — accogliere i cambiamenti con poco impegno/tempo/rischio (Gestione della Configurazione Software).
5. **Astrazione** — estrarre gli aspetti significativi trascurando i dettagli; produce modelli a diversi livelli per diversi destinatari.
6. **Generalità** — risolvere il problema generale di cui quello corrente è istanza; favorisce riuso e prodotti off-the-shelf.
7. **Incrementalità** — sviluppo per incrementi successivi; più validazioni, meno rischio.

Dettaglio in → [[principi-ingegneria-software]].

## Stream Coding (slide 44–52)

Adattamento dei principi allo sviluppo assistito da AI, in opposizione al *Vibe Coding* (conversazionale, caotico, che sacrifica rigore). Tesi: **la velocità è un sintomo, la chiarezza è la causa**. Cardini:

- **La Specifica come "Source of Truth"**.
- **Golden Rule:** se trovi un bug, **correggi la specifica e rigenera** — mai modificare il codice a mano.
- **Debito di Divergenza:** una modifica manuale al codice rompe la sincronia Specifica↔Implementazione.
- Mappatura: Rigore/Formalità → prompt strutturati e gate di chiarezza; Astrazione+Separazione → netta divisione Intento(documentazione)/Implementazione(generazione AI); Anticipazione → rigenerare interi moduli a costo ~zero.

Riferimento: `github.com/frmoretto/stream-coding`. Analisi completa e mappatura al progetto in → [[stream-coding]].

## Pagine collegate

- [[principi-ingegneria-software]] · [[stream-coding]]
- [[architettura-three-tier]] · [[direttive-leaf-mobility]] · [[leaf-mobility]]
