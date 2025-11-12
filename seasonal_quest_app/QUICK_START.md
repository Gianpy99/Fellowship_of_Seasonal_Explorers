# 🚀 Avvio Rapido - Seasonal Quest App

## Metodo 1: Collegamento Desktop (Consigliato)

### Creazione del Collegamento
Esegui una sola volta:
```powershell
.\CREATE_DESKTOP_SHORTCUT.ps1
```

### Utilizzo
1. **Clicca** sull'icona "Seasonal Quest App" sul desktop
2. Il sistema avvierà automaticamente:
   - 🖥️ **Image Server** (Node.js su porta 3000)
   - 🎨 **Flutter Web App** (in modalità debug)
   - 🌐 **Browser Chrome** con l'app

## Metodo 2: Script Manuale

Dalla cartella del progetto:
```cmd
START_APP.bat
```

## Cosa Succede all'Avvio

### 1. Image Server
- Verifica se il server è già attivo sulla porta 3000
- Se già attivo: **riutilizza** l'istanza esistente
- Se non attivo: avvia una **nuova istanza**
- Gestisce il salvataggio persistente delle immagini

### 2. Flutter Web App
- Compila l'app in modalità debug
- Apre automaticamente Chrome
- Supporta **Hot Reload** (premi `r` nella console)

### 3. Browser
- Si apre automaticamente su `http://localhost:PORTA`
- La porta è assegnata dinamicamente da Flutter

## 🔄 Hot Reload

Mentre l'app è in esecuzione, nella console Flutter puoi premere:
- `r` - **Hot Reload** (aggiorna UI senza perdere lo stato)
- `R` - **Hot Restart** (riavvia completamente l'app)
- `q` - **Quit** (chiude l'app)

## 🛑 Arresto

Per fermare completamente:
1. Chiudi il **browser**
2. Premi `Ctrl+C` o chiudi la **console Flutter**
3. (Opzionale) Chiudi la **console Image Server**

> **Nota**: Il server può rimanere attivo tra diverse sessioni dell'app!

## 📊 Struttura delle Finestre

All'avvio vedrai **2 finestre**:

| Finestra | Titolo | Porta | Scopo |
|----------|--------|-------|-------|
| 1️⃣ | `Seasonal Quest - Image Server` | 3000 | Gestione immagini e cache |
| 2️⃣ | `Seasonal Quest - Flutter App` | Dinamica | App Flutter e hot reload |

## 🐛 Troubleshooting

### Il server non si avvia
```cmd
netstat -ano | findstr ":3000"
```
Se la porta è occupata da altro processo, chiudilo o usa un'altra porta.

### Flutter non compila
```cmd
flutter clean
flutter pub get
flutter run -d chrome
```

### Il browser non si apre
Flutter aprirà automaticamente Chrome. Se non funziona, verifica:
```cmd
flutter devices
```

## 🎯 Tips

- **Prima esecuzione**: Attendi ~10-20 secondi per la compilazione
- **Successive esecuzioni**: ~3-5 secondi (hot reload)
- **Persistenza dati**: Le immagini sono salvate su disco e disponibili tra sessioni
- **Sviluppo**: Lascia il server attivo e riavvia solo Flutter quando serve

## 📝 File Importanti

- `START_APP.bat` - Script di avvio principale
- `CREATE_DESKTOP_SHORTCUT.ps1` - Crea collegamento desktop
- `image_server.js` - Server Node.js per gestione immagini
- `server_images/` - Cache persistente delle immagini

---

**Buon sviluppo!** 🚀
