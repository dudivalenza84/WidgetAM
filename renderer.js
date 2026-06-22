// Elementos da UI
const albumArt = document.getElementById('album-art');
const trackTitle = document.getElementById('track-title');
const trackArtist = document.getElementById('track-artist');
const currentTimeLabel = document.getElementById('current-time');
const totalDurationLabel = document.getElementById('total-duration');
const progressBar = document.getElementById('progress-bar');
const playPauseBtn = document.getElementById('play-pause-btn');
const playIcon = document.getElementById('play-icon');
const pauseIcon = document.getElementById('pause-icon');
const prevBtn = document.getElementById('prev-btn');
const nextBtn = document.getElementById('next-btn');
const volumeBar = document.getElementById('volume-bar');
const muteBtn = document.getElementById('mute-btn');

// Imagem SVG padrão caso não haja reprodução
const defaultArtwork = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100' viewBox='0 0 100 100'><rect width='100' height='100' fill='%23222'/><path d='M30 30h40v40H30z' fill='%23444'/><circle cx='50' cy='50' r='10' fill='%23666'/></svg>";

// Estados de arrasto do usuário (para evitar que a atualização automática interrompa a interação)
let isDraggingProgress = false;
let isDraggingVolume = false;
let currentVolume = 0.5;

// Formata segundos para MM:SS
function formatTime(secs) {
  if (isNaN(secs) || secs === null || secs < 0) return '0:00';
  const m = Math.floor(secs / 60);
  const s = Math.floor(secs % 60);
  return `${m}:${s < 10 ? '0' : ''}${s}`;
}

// Atualiza a interface com as informações do player
window.mediaAPI.onMediaUpdate((data) => {
  if (!data.success) {
    // Estado ocioso/sem reprodução ativa
    trackTitle.textContent = "Sem reprodução";
    
    if (data.error && (data.error.includes("JavaScript") || data.error.includes("AppleScript") || data.error.includes("desativada") || data.error.includes("disabled") || data.error.includes("Eventos da Apple"))) {
      trackArtist.style.whiteSpace = 'normal';
      trackArtist.style.fontSize = '9px';
      trackArtist.style.color = '#ff453a'; // Vermelho macOS
      trackArtist.textContent = "Ative no Chrome: Ver > Desenvolvedor > Permitir JavaScript de Eventos da Apple";
    } else {
      trackArtist.style.whiteSpace = 'nowrap';
      trackArtist.style.fontSize = '12px';
      trackArtist.style.color = 'rgba(255, 255, 255, 0.6)';
      trackArtist.textContent = data.reason === "chrome_not_running" 
        ? "Google Chrome não está aberto" 
        : "Abra o Amazon Music no Chrome";
    }
    
    if (albumArt.src !== defaultArtwork) {
      albumArt.src = defaultArtwork;
    }
    
    currentTimeLabel.textContent = "0:00";
    totalDurationLabel.textContent = "0:00";
    progressBar.value = 0;
    progressBar.max = 100;
    
    playIcon.classList.remove('hidden');
    pauseIcon.classList.add('hidden');
    return;
  }

  // Reset de estilos do estado de erro
  trackArtist.style.whiteSpace = 'nowrap';
  trackArtist.style.fontSize = '12px';
  trackArtist.style.color = 'rgba(255, 255, 255, 0.6)';

  // Atualiza capa do álbum (evita piscar se for a mesma URL)
  const artworkSrc = data.artwork || defaultArtwork;
  if (albumArt.src !== artworkSrc) {
    albumArt.src = artworkSrc;
  }

  // Atualiza metadados
  trackTitle.textContent = data.title || "Desconhecido";
  trackArtist.textContent = data.artist || "Amazon Music";

  // Alterna ícones de Play/Pause
  if (data.paused) {
    playIcon.classList.remove('hidden');
    pauseIcon.classList.add('hidden');
  } else {
    playIcon.classList.add('hidden');
    pauseIcon.classList.remove('hidden');
  }

  // Atualiza Barra de Progresso
  if (!isDraggingProgress) {
    progressBar.max = data.duration || 100;
    progressBar.value = data.currentTime || 0;
    currentTimeLabel.textContent = formatTime(data.currentTime);
    totalDurationLabel.textContent = formatTime(data.duration);
  }

  // Atualiza Barra de Volume
  if (!isDraggingVolume) {
    currentVolume = data.volume !== undefined ? data.volume : 0.5;
    volumeBar.value = currentVolume * 100;
  }
});

// Eventos de Controle de Reprodução
playPauseBtn.addEventListener('click', () => {
  window.mediaAPI.sendCommand('play-pause');
});

nextBtn.addEventListener('click', () => {
  window.mediaAPI.sendCommand('next');
});

prevBtn.addEventListener('click', () => {
  window.mediaAPI.sendCommand('prev');
});

// Eventos do Slider de Progresso (Seek)
progressBar.addEventListener('mousedown', () => { isDraggingProgress = true; });
progressBar.addEventListener('mouseup', () => { isDraggingProgress = false; });
progressBar.addEventListener('touchstart', () => { isDraggingProgress = true; });
progressBar.addEventListener('touchend', () => { isDraggingProgress = false; });

progressBar.addEventListener('input', () => {
  currentTimeLabel.textContent = formatTime(progressBar.value);
});

progressBar.addEventListener('change', () => {
  window.mediaAPI.sendCommand('seek', parseFloat(progressBar.value));
});

// Eventos do Slider de Volume
volumeBar.addEventListener('mousedown', () => { isDraggingVolume = true; });
volumeBar.addEventListener('mouseup', () => { isDraggingVolume = false; });
volumeBar.addEventListener('touchstart', () => { isDraggingVolume = true; });
volumeBar.addEventListener('touchend', () => { isDraggingVolume = false; });

volumeBar.addEventListener('input', () => {
  currentVolume = parseFloat(volumeBar.value) / 100;
});

volumeBar.addEventListener('change', () => {
  window.mediaAPI.sendCommand('volume', currentVolume);
});

// Toggle Mute
muteBtn.addEventListener('click', () => {
  const newVolume = currentVolume > 0 ? 0 : 0.5;
  currentVolume = newVolume;
  volumeBar.value = newVolume * 100;
  window.mediaAPI.sendCommand('volume', newVolume);
});
