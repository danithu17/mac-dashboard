# 🍏 PulseHabit Pro

> **The Ultimate Apple-Ecosystem Productivity & Habit Tracking Suite.**  
> Seamlessly unified across **Web**, **Desktop (Windows)**, and **Mobile (Android)** with zero-cost live synchronization.

[![Live Web](https://img.shields.io/badge/Live%20Web-mac--dashboard--mu.vercel.app-007AFF?style=for-the-badge&logo=vercel&logoColor=white)](https://mac-dashboard-mu.vercel.app/)
[![Desktop Release](https://img.shields.io/badge/Desktop%20Installer-v1.0.0--desktop-blueviolet?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/danithu17/mac-dashboard/releases/tag/v1.0.0-desktop)
[![Android Release](https://img.shields.io/badge/Android%20APK-v1.0.0--android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/danithu17/mac-dashboard/releases/tag/v1.0.0-android)
[![License: MIT](https://img.shields.io/badge/License-MIT-black?style=for-the-badge)](LICENSE)

---

## 🌐 Live Web Deployment
Experience PulseHabit Pro instantly in any modern browser:  
👉 **[https://mac-dashboard-mu.vercel.app/](https://mac-dashboard-mu.vercel.app/)**

---

## 📱 Cross-Platform Ecosystem

| Platform | Format | Status | Download / Link |
| :--- | :--- | :--- | :--- |
| **🌐 Web App** | Responsive PWA | 🟢 Live | [Open Web App](https://mac-dashboard-mu.vercel.app/) |
| **🖥️ Windows Desktop** | Native NSIS Installer (`.exe`) | 🟢 Released | [Download Windows Setup](https://github.com/danithu17/mac-dashboard/releases/tag/v1.0.0-desktop) |
| **📱 Android Mobile** | Native Flutter APK (`.apk`) | 🟢 Released | [Download Android APK](https://github.com/danithu17/mac-dashboard/releases/tag/v1.0.0-android) |

---

## ✨ Features & Apple Aesthetics

- **macOS Sequoia Floating Glass Dock**:
  - Re-engineered with authentic 3D skeuomorphic icons for PulseHabit, New Habit, Activity Rings, Awards, Quick Notes, Focus Timer, and System Settings.
  - Interactive hover magnification, tooltips, active dot indicators, and ultra-smooth animations.
- **Apple Fitness Activity Rings**:
  - Concentric SVG activity rings tracking:
    - 🔴 **Move / Daily Habits**
    - 🟢 **Exercise / Focus Sessions**
    - 🔵 **Stand / Streak Consistency**
- **Focus Pomodoro Timer**:
  - Deep-work countdown timer with customizable interval presets, ambient soundscapes, and automatic XP rewards.
- **Apple Watch Awards Gallery**:
  - Metallic 3D medals unlocking dynamically based on streak milestones, completion ratios, and total XP accumulated.
- **Quick Notes & Mood Tracking**:
  - Sticky scratchpad inspired by macOS Notes and iOS mental wellbeing logs.
- **Zero-Cost Multi-Device Sync**:
  - Local-first architecture with automatic synchronization to Vercel/Node.js backend, keeping all your devices up to date with 0 cloud server costs.

---

## 🛠️ Development & Building

### 1. Web Version
```bash
# Run locally with Node
npm install
npm start
# Open http://localhost:3000
```

### 2. Desktop Version (Electron + NSIS)
```bash
cd desktop
npm install
npm run dist
# Generates installer in desktop/dist/installer/
```

### 3. Android Version (Flutter)
```bash
cd android
flutter pub get
flutter build apk --release
# Generates APK in android/build/app/outputs/flutter-apk/app-release.apk
```

---

## 📄 License
This project is open-source under the [MIT License](LICENSE).
