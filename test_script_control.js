const { spawn } = require('child_process');

function runAppleScript(script) {
  return new Promise((resolve) => {
    const child = spawn('osascript', []);
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (data) => { stdout += data; });
    child.stderr.on('data', (data) => { stderr += data; });
    child.on('close', (code) => {
      resolve({ code, stdout: stdout.trim(), stderr: stderr.trim() });
    });
    child.stdin.write(script);
    child.stdin.end();
  });
}

// Código JS com aspas duplas normais
let jsCode = `
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

// Escapa corretamente barra invertida, aspas duplas e novas linhas para o AppleScript
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

console.log('Script enviado para osascript:\n', script);

runAppleScript(script).then((res) => {
  console.log('Exit Code:', res.code);
  console.log('Stdout:', res.stdout);
  console.log('Stderr:', res.stderr);
});
