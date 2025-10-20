# Automazione salvataggio immagini in `assets/images/generated`

Questa guida descrive due opzioni per salvare automaticamente le immagini generate o caricate dall'app Flutter nella cartella `assets/images/generated` del progetto.

## Opzione A — Server locale (consigliata, più robusta)
1. Avvia il server Node che ho aggiunto in `tools/save_image_server.js`:

```bash
cd seasonal_quest_app/tools
npm init -y
npm install express body-parser cors
node save_image_server.js
```

2. Dal browser (Console) o dall'app, effettua una POST a `http://localhost:4567/save-image` con JSON:

```json
{ "filename": "bergamotto_calabria_icon.png", "base64": "...base64 data..." }
```

Esempio rapido da Console (se la base64 è in LocalStorage `seasonal_quest_image_bergamotto_calabria_icon`):

```javascript
(async ()=>{
  const key = 'seasonal_quest_image_bergamotto_calabria_icon';
  const base64 = localStorage.getItem(key);
  const filename = 'bergamotto_calabria_icon.png';
  if (!base64) return console.error('No key');
  const res = await fetch('http://localhost:4567/save-image', {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    body: JSON.stringify({ filename, base64 })
  });
  console.log(await res.json());
})();
```

Il server salverà il file in `seasonal_quest_app/assets/images/generated/` immediatamente. Poi fai `r` per hot reload e l'immagine sarà caricata dall'app.

---

## Opzione B — Watcher PowerShell (semplice, non richiede server)
1. Avvia lo script PowerShell `tools/save_images_watcher.ps1`:

```powershell
cd seasonal_quest_app\tools
.\save_images_watcher.ps1
```

2. Lo script monitora la tua cartella `Downloads` e copia automaticamente i file PNG in `assets/images/generated/` appena appaiono.
   - Se il nome contiene `_icon` o `_story` mantiene il nome.
   - Altrimenti lo copia con prefisso `imported_`.

3. Dopo la copia, fai `r` per hot reload.

---

## Note e suggerimenti
- Flutter Web **non può** modificare il filesystem del progetto direttamente dalla pagina web: per questo servono strumenti locali (server o watcher).
- Il server Node è più flessibile: puoi integrare l'app per POSTare direttamente il base64 e automatizzare tutto.
- Il watcher è utile se preferisci non far girare un server: basta che il browser salvi il PNG in Download (il servizio lo fa automaticamente) e lo script lo copierà in assets.

Se vuoi, posso:
- Aggiungere un pulsante nell'app che prova a chiamare `http://localhost:4567/save-image` automaticamente dopo il download (se il server è presente);
- Modificare il nome del file scaricato per aderire sempre al pattern `{productId}_icon.png` così il watcher lo sposti senza rinominarlo;
- Fornirti uno script PowerShell extra che rinomina file scaricati secondo una mappa `downloadName -> desiredAssetName`.

Dimmi quale preferisci e procedo ad implementarlo.