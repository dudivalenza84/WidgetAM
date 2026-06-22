const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('mediaAPI', {
  onMediaUpdate: (callback) => {
    ipcRenderer.on('media-update', (event, data) => callback(data));
  },
  sendCommand: (command, value) => {
    return ipcRenderer.invoke('send-media-command', { command, value });
  }
});
