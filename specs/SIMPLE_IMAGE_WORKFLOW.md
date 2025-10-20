# 🎨 Simple AI Image Workflow

## Come Funziona (SEMPLICE!)

### Durante la Sessione
1. **Clicca "Generate Product Icon"** o **"Generate AI Illustration"**
2. **Modifica il prompt** (opzionale)
3. L'app:
   - ✅ Genera l'immagine con Gemini AI
   - ✅ Mostra immediatamente in memoria (veloce!)
   - ✅ **Scarica automaticamente** il file PNG
4. Trovi il file nella cartella **Download** del browser

### Salvataggio Permanente
1. **Copia manualmente** i file PNG scaricati in:
   ```
   seasonal_quest_app/assets/images/generated/
   ```

2. **Naming convention**:
   - Icon: `{product_id}_icon.png` (es: `bergamotto_calabria_icon.png`)
   - Story: `{product_id}_story_{index}.png` (es: `bergamotto_calabria_story_0.png`)
   - Recipe: `{product_id}_recipe.png`

3. **Hot reload** (`r` nel terminale) o riavvia l'app

4. L'app carica automaticamente da `assets/images/generated/`

## Vantaggi

✅ **SEMPLICE**: No IndexedDB, no LocalStorage, no complicazioni!
✅ **TRASPARENTE**: Vedi esattamente dove sono salvate le immagini
✅ **PERMANENTE**: File PNG nel progetto, versionate con Git
✅ **VELOCE**: Memory cache durante la sessione
✅ **AUTOMATICO**: Download automatico, niente click extra

## Workflow Completo

```
1. Genera immagine → 2. Download automatico → 3. Copia in assets/ → 4. Hot reload
       ↓                       ↓                         ↓                  ↓
   Gemini AI          File in Download          Salvataggio permanente   App carica
```

## Struttura Directory

```
seasonal_quest_app/
├── assets/
│   ├── images/
│   │   └── generated/        ← Copia qui i PNG scaricati!
│   │       ├── bergamotto_calabria_icon.png
│   │       ├── bergamotto_calabria_story_0.png
│   │       ├── limone_calabria_icon.png
│   │       └── ...
│   └── seasonal_data.json
```

## Note Tecniche

- **Memory Cache**: Durante la sessione, immagini in RAM (Uint8List)
- **Asset Loading**: Al riavvio, `Image.asset()` da `assets/images/generated/`
- **Fallback**: Se file non esiste in assets, mostra emoji
- **No Browser Cache**: Sempre carica da assets/, mai da cache browser

## Esempio Pratico

1. **Genera icona Bergamotto**:
   - File scaricato: `bergamotto_calabria_icon.png`
   - SnackBar: "Icon generated! Copy to: assets/images/generated/bergamotto_calabria_icon.png"

2. **Copia file**:
   ```powershell
   copy ~\Downloads\bergamotto_calabria_icon.png seasonal_quest_app\assets\images\generated\
   ```

3. **Hot reload**:
   - Premi `r` nel terminale
   - L'icona appare nella home screen!

## Troubleshooting

**Q: L'immagine non appare dopo hot reload?**  
A: Verifica che il file sia in `assets/images/generated/` con il nome corretto

**Q: Posso generare batch di immagini?**  
A: Sì, genera tutte le immagini, poi copia tutti i PNG in una volta

**Q: I file sono versionati con Git?**  
A: Sì! `assets/images/generated/` è nel repository
