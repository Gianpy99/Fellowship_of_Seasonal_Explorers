#!/usr/bin/env node
/**
 * 🌍 SEASONAL QUEST APP - Master Launcher
 * Avvia sia il server Image che l'app Flutter Web
 * in processi separati
 */

const { spawn, exec } = require('child_process');
const path = require('path');
const os = require('os');

const APP_DIR = __dirname;
const PORT_SERVER = 3000;
const PORT_FLUTTER = 5000;

console.log('\n╔════════════════════════════════════════════╗');
console.log('║  🌍 SEASONAL QUEST APP - Master Launcher   ║');
console.log('╚════════════════════════════════════════════╝\n');

// ✅ Funzione per avviare il server Node.js
function startImageServer() {
  console.log('🚀 [1/2] Avvio Image Server su http://localhost:' + PORT_SERVER);
  
  const serverProcess = spawn('node', ['image_server.js'], {
    cwd: APP_DIR,
    stdio: ['ignore', 'inherit', 'inherit'],
    detached: true
  });

  serverProcess.on('error', (err) => {
    console.error('❌ Errore nell\'avvio del server:', err);
    process.exit(1);
  });

  return serverProcess;
}

// ✅ Funzione per avviare Flutter
function startFlutterApp() {
  console.log('🚀 [2/2] Avvio Flutter App su http://localhost:' + PORT_FLUTTER);
  console.log('⏳ Aspetta 3 secondi che il server si avvii...\n');
  
  setTimeout(() => {
    const flutterProcess = spawn('flutter', ['run', '-d', 'chrome'], {
      cwd: APP_DIR,
      stdio: 'inherit',
      detached: false
    });

    flutterProcess.on('error', (err) => {
      console.error('❌ Errore nell\'avvio di Flutter:', err);
      process.exit(1);
    });

    flutterProcess.on('exit', (code) => {
      console.log('\n✅ App chiusa');
      console.log('💡 Il server continua a girare. Premi Ctrl+C per chiudere tutto.');
      process.exit(0);
    });
  }, 3000);
}

// 🛑 Gestione di Ctrl+C
process.on('SIGINT', () => {
  console.log('\n\n🛑 Arresto dell\'applicazione...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n🛑 Arresto dell\'applicazione...');
  process.exit(0);
});

// 🚀 Avvia tutto
try {
  startImageServer();
  startFlutterApp();
} catch (err) {
  console.error('❌ Errore:', err);
  process.exit(1);
}
