const { app, BrowserWindow, ipcMain, screen } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let mainWindow = null;
let updateInterval = null;

// Executa AppleScript via stdin para evitar problemas de escape de shell
function runAppleScript(script) {
  return new Promise((resolve) => {
    const child = spawn('osascript', []);
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (data) => { stdout += data; });
    child.stderr.on('data', (data) => { stderr += data; });
    child.on('close', (code) => {
      if (code === 0) {
        resolve({ success: true, output: stdout.trim() });
      } else {
        resolve({ success: false, error: stderr.trim() });
      }
    });
    child.stdin.write(script);
    child.stdin.end();
  });
}

function createWindow() {
  // Esconde o ícone no dock antes de criar a janela para ser puramente um widget
  if (process.platform === 'darwin') {
    app.dock.hide();
  }

  // Pega o tamanho da tela para posicionar no canto superior direito
  const primaryDisplay = screen.getPrimaryDisplay();
  const { width } = primaryDisplay.workAreaSize;
  const widgetWidth = 350;
  const widgetHeight = 155;
  const paddingX = 20;
  const paddingY = 40;

  mainWindow = new BrowserWindow({
    width: widgetWidth,
    height: widgetHeight,
    x: width - widgetWidth - paddingX,
    y: paddingY,
    frame: false,
    transparent: true,
    resizable: false,
    movable: true, // Permitir arrastar se segurar na área do widget
    skipTaskbar: true,
    hasShadow: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
    },
  });

  mainWindow.loadFile('index.html');

  // Configurações específicas para macOS se comportar como widget de mesa
  if (process.platform === 'darwin') {
    // Aparece em todas as áreas de trabalho virtuais (Spaces)
    mainWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: false });
    // Mantém no nível da mesa (desktop level), abaixo das janelas normais
    mainWindow.setAlwaysOnTop(true, 'desktop');
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
    clearInterval(updateInterval);
  });

  // Loop de consulta do estado da música (a cada 1 segundo)
  updateInterval = setInterval(queryMediaState, 1000);
}

// Consulta o status do player do Amazon Music
async function queryMediaState() {
  if (!mainWindow) return;

  const script = `
    if application "Google Chrome" is running then
      tell application "Google Chrome"
        set foundTab to false
        set resultJSON to ""
        repeat with w in windows
          repeat with t in tabs of w
            if URL of t contains "music.amazon.com" then
              set foundTab to true
              set resultJSON to (execute t javascript "
                (function() {
                  try {
                    const audio = document.querySelector('audio');
                    const metadata = navigator.mediaSession?.metadata;
                    
                    let artworkUrl = '';
                    if (metadata && metadata.artwork && metadata.artwork.length > 0) {
                      artworkUrl = metadata.artwork[0].src;
                    } else {
                      const img = document.querySelector('#nowPlayingImage img') || document.querySelector('.nowPlayingImage img') || document.querySelector('.keep-album-art img') || document.querySelector('img[alt=\\"Album Art\\"]');
                      if (img) artworkUrl = img.src;
                    }
                    
                    return JSON.stringify({
                      success: true,
                      title: metadata?.title || document.title.split(' - ')[0] || 'Desconhecido',
                      artist: metadata?.artist || document.title.split(' - ')[1] || 'Amazon Music',
                      artwork: artworkUrl,
                      paused: audio ? audio.paused : true,
                      currentTime: audio ? audio.currentTime : 0,
                      duration: audio ? audio.duration : 0,
                      volume: audio ? audio.volume : 0.5
                    });
                  } catch(e) {
                    return JSON.stringify({ success: false, error: e.message });
                  }
                })()
              ")
              exit repeat
            end if
          end repeat
          if foundTab then exit repeat
        end repeat
        if not foundTab then
          return "{\\"success\\": false, \\"reason\\": \\"tab_not_found\\"}"
        else
          return resultJSON
        end if
      end tell
    else
      return "{\\"success\\": false, \\"reason\\": \\"chrome_not_running\\"}"
    end if
  `;

  const res = await runAppleScript(script);
  if (res.success && res.output) {
    try {
      const data = JSON.parse(res.output);
      mainWindow.webContents.send('media-update', data);
    } catch (e) {
      mainWindow.webContents.send('media-update', { success: false, error: 'JSON parse error' });
    }
  } else {
    mainWindow.webContents.send('media-update', { success: false, error: res.error });
  }
}

// Handler para comandos enviados pelo frontend
ipcMain.handle('send-media-command', async (event, { command, value }) => {
  let jsCode = '';
  switch (command) {
    case 'play-pause':
      jsCode = `
        (function() {
          const playBtn = document.querySelector('music-button[icon-name="play"]') || document.querySelector('button[aria-label="Play"]') || document.querySelector('[data-automation-id="play-button"]');
          const pauseBtn = document.querySelector('music-button[icon-name="pause"]') || document.querySelector('button[aria-label="Pause"]') || document.querySelector('[data-automation-id="pause-button"]');
          if (playBtn) {
            playBtn.click();
          } else if (pauseBtn) {
            pauseBtn.click();
          } else {
            const audio = document.querySelector('audio');
            if (audio) audio.paused ? audio.play() : audio.pause();
          }
        })()
      `;
      break;
    case 'next':
      jsCode = `
        (function() {
          const nextBtn = document.querySelector('music-button[icon-name="next"]') || document.querySelector('button[aria-label="Next"]') || document.querySelector('.nextButton') || document.querySelector('[data-automation-id="next-button"]');
          if (nextBtn) nextBtn.click();
        })()
      `;
      break;
    case 'prev':
      jsCode = `
        (function() {
          const prevBtn = document.querySelector('music-button[icon-name="previous"]') || document.querySelector('button[aria-label="Previous"]') || document.querySelector('.prevButton') || document.querySelector('[data-automation-id="previous-button"]');
          if (prevBtn) prevBtn.click();
        })()
      `;
      break;
    case 'volume':
      jsCode = `
        (function() {
          const audio = document.querySelector('audio');
          if (audio) audio.volume = ${value};
        })()
      `;
      break;
    case 'seek':
      jsCode = `
        (function() {
          const audio = document.querySelector('audio');
          if (audio) audio.currentTime = ${value};
        })()
      `;
      break;
  }

  if (!jsCode) return { success: false, error: 'Comando inválido' };

  // Escapa barras invertidas, aspas duplas e remove novas linhas para o osascript
  const escapedJs = jsCode
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, ' ');

  const script = `
    tell application "Google Chrome"
      repeat with w in windows
        repeat with t in tabs of w
          if URL of t contains "music.amazon.com" then
            execute t javascript "${escapedJs}"
            return "success"
          end if
        end repeat
      end repeat
    end tell
  `;

  return await runAppleScript(script);
});

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
