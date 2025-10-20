# 🌍 Seasonal Quest App - Guida di Avvio

## Quick Start

### ⭐ Modo più facile: Doppio-click su `START_APP.bat`

Questo file avvia automaticamente:
1. **Image Server** (Node.js) - porta 3000
2. **Flutter Web App** - porta 5000 (Chrome)

**Requisiti:**
- ✅ Node.js installato (per il server)
- ✅ Flutter installato (per l'app)

---

## 🎯 Cosa succede al primo avvio?

```
Starting Image Server (port 3000)...
Starting Flutter App (port 5000)...

Resolving dependencies...  ← Prima volta: ~30 sec (scarica pacchetti)
Launching lib\main.dart on Chrome...
```

### Perché la prima volta è lenta?

Flutter ricarica i pacchetti perché è un **web framework** che:
1. Scarica le dipendenze Dart
2. Compila il codice in JavaScript
3. Lancia il browser con hot-reload

**Questa è una cosa NORMALE di Flutter Web**, non è un problema.

---

## ⚡ Come velocizzare i riavvii successivi?

### Opzione 1: Usa `r` (Hot Reload) - CONSIGLIATO
Mentre l'app è aperta nel terminal Flutter:
```
r     ← Hot reload (1-2 sec)
R     ← Hot restart (3-5 sec)
q     ← Quit app
```

**Non chiudere il .bat!** Lascia il server girare e usa `r` per reloadare il codice.

### Opzione 2: Chiudi solo l'app, non il server
```
Premi q nel terminal Flutter  ← App si chiude
Server rimane acceso su porta 3000
flutter run -d chrome        ← Riavvia solo l'app (più veloce)
```

### Opzione 3: Se devi riavviare tutto
```
Chiudi il .bat
Doppio-click di nuovo su START_APP.bat

⚠️ Questa volta Flutter ricompila (lento)
```

---

## 📍 Indirizzi

| Servizio | URL | Uso |
|----------|-----|-----|
| **App** | http://localhost:5000 | L'app Flutter (aperta auto in Chrome) |
| **Image Server** | http://localhost:3000/api/health | Verificare se il server è acceso |
| **Images Storage** | `server_images/` (cartella) | Dove vengono salvate le immagini |

---

## 🐛 Troubleshooting

### Errore: "flutter is not recognized"
**Soluzione:** Il file `START_APP.bat` non trova Flutter nel PATH. Controlla:
```powershell
Get-Command flutter
```

Se non lo trova, aggiorna il percorso in `START_APP.bat` alla riga:
```batch
"C:\Users\gianp\OneDrive\Documents\flutter\bin\flutter.bat" run -d chrome
```

### Errore: "node is not recognized"
**Soluzione:** Node.js non è nel PATH. Installa da https://nodejs.org/

### Porta 3000 o 5000 occupata
**Soluzione:** 
```powershell
# Trovo che cosa occupa la porta
netstat -ano | findstr :3000
netstat -ano | findstr :5000

# Uccido il processo (es. PID 1234)
taskkill /PID 1234 /F
```

### Le immagini si perdono tra i riavvi
**Soluzione:** Le immagini vengono salvate in `server_images/`. Se non le vedi:
1. Verificare che la cartella `server_images` sia stata creata
2. Controllare i log del server per errori

---

## 📊 Monitoraggio

### Aprire il pannello di controllo del server

Mentre il server è in esecuzione, apri in browser:
```
http://localhost:3000/api/health
```

Questo ti mostra quante immagini sono salvate.

---

## 🎨 Workflow di sviluppo consigliato

1. **Start:** Doppio-click `START_APP.bat`
2. **Modifica il codice** in VSCode
3. **Reload:** Premi `r` nel terminal Flutter
4. **Test:** Guarda le modifiche in tempo reale
5. **Fine:** Premi `q` nel terminal Flutter
6. **Pulisci:** Chiudi il .bat

---

## 💾 Dati persistenti

- **Immagini**: Salvate in `server_images/` (disco)
- **Quest state**: Salvato in browser (localStorage)
- **Custom prompts**: Salvati in JSON del quest

Tutto persiste tra i riavvi! ✅

---

## 🚀 Prossimi step

- [ ] Generare immagini per Bergamotto
- [ ] Testare il salvataggio persistente
- [ ] Esplorare altre stagioni
- [ ] Configurare Google Maps API
- [ ] Aggiungere foto dalla webcam

---

**Domande?** Controlla i log nel terminal! 📋
