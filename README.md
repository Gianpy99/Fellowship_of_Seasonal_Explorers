# Seasonal Products Database — Story Edition

Questo repository contiene un database completo di **prodotti stagionali** per il Sud Italia (Calabria) e il Sud dell'Inghilterra,
arricchito con **micro-storie** in stile Tolkien + Ghibli + Disney per un pubblico di famiglie e bambini.

## Contenuto del file JSON

Il file `seasonal_db_complete_story_cards__WITH_3x_stories_YYYYMMDD.json` contiene una lista di prodotti,
ognuno con i seguenti campi principali:

- `name_it` — Nome del prodotto in italiano
- `name_en` — Nome del prodotto in inglese
- `type` — Categoria del prodotto (`fruit`, `vegetable`, `flower`, `animal_product`)
- `season` — Mesi di raccolta per `southern_italy` e `southern_england`
- `available_on_shelves` — Mesi di disponibilità sugli scaffali
- `icon` — Nome file icona
- `recipes` — Ricette semplici e family-friendly per Sud Italia e Sud Inghilterra
- `educational_text` — Testo educativo
- `story` — 3 micro-storie in italiano e inglese, nello stile Tolkien+Ghibli+Disney, con personaggi ricorrenti:
  - **Lina** — Bambina curiosa della Calabria
  - **Taro** — Folletto viaggiatore dal Sud Inghilterra
  - **Nonna Rosa** — Custode di antiche tradizioni e saggezza
  - **Piuma** — Pettirosso parlante, compagno di avventure

### Struttura del campo `story`
```json
"story": {
  "it": [
    "Prima storia in italiano",
    "Seconda storia in italiano",
    "Terza storia in italiano"
  ],
  "en": [
    "First story in English",
    "Second story in English",
    "Third story in English"
  ]
}
```

## Come usare il file

1. **Educazione alimentare** — Mostrare ai bambini la stagionalità e l'origine dei prodotti.
2. **App interattive** — Collegare storie, immagini e stagionalità in un'interfaccia grafica.
3. **Materiale didattico** — Utilizzabile in scuole primarie o laboratori di cucina per bambini.

## Licenza

Puoi usare e modificare questo file liberamente per scopi educativi e non commerciali.
Per usi commerciali, richiedere autorizzazione.

---
© 2025 — Progetto educativo stagionalità con storie fiabesche.
