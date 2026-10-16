const { app, BrowserWindow, Menu, Tray, nativeImage, ipcMain, Notification } = require('electron');
const path = require('path');

// Disable GPU disk caches and features that trigger Windows access lock errors (0x20 / 0x5)
app.commandLine.appendSwitch('disable-gpu-shader-disk-cache');
app.commandLine.appendSwitch('disable-gpu-program-cache');
app.commandLine.appendSwitch('disable-features', 'DawnGraphite,PersistentGpuCache');

// Single instance lock to prevent duplicate concurrent processes locking caches
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  // If another instance is already running, quit immediately to prevent lock contention
  app.quit();
} else {
  let mainWindow = null;

  app.on('second-instance', () => {
    // When someone tries to launch a second instance, focus the existing window
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });

  function createWindow() {
    mainWindow = new BrowserWindow({
      width: 1280,
      height: 860,
      minWidth: 840,
      minHeight: 600,
      title: 'PulseHabit Pro',
      frame: false, // Frameless for pure authentic Apple unified window
      backgroundColor: '#0b0f19',
      show: false,
      webPreferences: {
        preload: path.join(__dirname, 'preload.js'),
        nodeIntegration: false,
        contextIsolation: true,
        sandbox: false
      }
    });

    const fs = require('fs');
    const localWebPath = path.join(__dirname, 'web', 'index.html');
    const fallbackPath = path.join(__dirname, '..', 'web', 'index.html');
    const webIndexPath = fs.existsSync(localWebPath) ? localWebPath : fallbackPath;
    mainWindow.loadFile(webIndexPath);

    mainWindow.once('ready-to-show', () => {
      mainWindow.show();
    });

    mainWindow.on('closed', () => {
      mainWindow = null;
    });
  }

  // Traffic light IPC handlers
  ipcMain.on('window-minimize', () => {
    if (mainWindow) mainWindow.minimize();
  });

  ipcMain.on('window-maximize', () => {
    if (mainWindow) {
      if (mainWindow.isMaximized()) {
        mainWindow.unmaximize();
      } else {
        mainWindow.maximize();
      }
    }
  });

  ipcMain.on('window-close', () => {
    if (mainWindow) mainWindow.close();
  });

  // Native Desktop OS Notifications
  ipcMain.on('native-notification', (event, { title, body }) => {
    if (Notification.isSupported()) {
      new Notification({
        title: title || 'PulseHabit Pro',
        body: body || 'Habit notification',
        silent: false
      }).show();
    }
  });

  app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
      }
    });
  });

  app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
      app.quit();
    }
  });
}
