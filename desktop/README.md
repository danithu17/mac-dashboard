#  PulseHabit Pro — Desktop App (Electron)

PulseHabit Pro Native Desktop Application for macOS & Windows with authentic macOS Sequoia glassmorphism, native traffic lights, system notifications, and offline sync.

---

## 🚀 Running the Desktop App

From the project root:
```bash
npm run dev:desktop
```
Or directly from the `desktop/` folder:
```bash
cd desktop
npx electron .
```

---

## 🛠 Features in Desktop Mode

1. **Native Window Controls**:
   - Red traffic light closes the app window.
   - Yellow traffic light minimizes the window.
   - Green traffic light maximizes/unmaximizes the window.
2. **Draggable Window Header**:
   - Click and drag anywhere along the top title bar to move the window across monitors.
3. **Native Desktop OS Notifications**:
   - System notifications trigger when a Pomodoro focus session finishes (+25 XP).
4. **Offline Capability & Live Sync**:
   - Loads instantly from local disk with 0ms network latency.
   - Automatically synchronizes with your local or cloud server (`/api/sync/:uid`) when connected.

---

## 📦 Building Standalone Installers (.exe / .dmg)

To package into a production installer:
```bash
cd desktop
npm install -D electron-builder
npx electron-builder
```
This produces:
- Windows: `dist/PulseHabit Pro Setup 1.0.0.exe`
- macOS: `dist/PulseHabit Pro-1.0.0.dmg`
