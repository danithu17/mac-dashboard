const { app, BrowserWindow, Menu, Tray, nativeImage, ipcMain, Notification, shell } = require('electron');
const path = require('path');
const fs = require('fs');

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
      icon: path.join(__dirname, 'assets', process.platform === 'win32' ? 'icon.ico' : 'icon.png'),
      backgroundColor: '#0b0f19',
      show: false,
      webPreferences: {
        preload: path.join(__dirname, 'preload.js'),
        nodeIntegration: false,
        contextIsolation: true,
        sandbox: true, // Security hardening
        webSecurity: true,
        allowRunningInsecureContent: false
      }
    });

    // Security: Intercept external link popups and open safely in user's OS browser
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
      if (url.startsWith('https://') || url.startsWith('http://')) {
        shell.openExternal(url);
      }
      return { action: 'deny' };
    });

    // Security: Prevent malicious in-app navigation
    mainWindow.webContents.on('will-navigate', (event, navigationUrl) => {
      try {
        const parsedUrl = new URL(navigationUrl);
        if (parsedUrl.protocol !== 'file:') {
          event.preventDefault();
          if (navigationUrl.startsWith('https://') || navigationUrl.startsWith('http://')) {
            shell.openExternal(navigationUrl);
          }
        }
      } catch (e) {
        event.preventDefault();
      }
    });

    // Security: Deny all sensitive permission requests (camera, mic, geolocation, notifications)
    mainWindow.webContents.session.setPermissionRequestHandler((webContents, permission, callback) => {
      return callback(false);
    });

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

  // Native Desktop OS Notifications (Sanitized)
  ipcMain.on('native-notification', (event, { title, body }) => {
    if (Notification.isSupported()) {
      new Notification({
        title: typeof title === 'string' ? title.slice(0, 100) : 'PulseHabit Pro',
        body: typeof body === 'string' ? body.slice(0, 200) : 'Habit notification',
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
