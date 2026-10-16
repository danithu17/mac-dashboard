# PulseHabit Pro — Android Edition (Flutter Cupertino)

A high-performance Android companion application for **PulseHabit Pro**, crafted with authentic Apple Cupertino design language, activity rings, streak tracking, and cost-free live synchronization with Web and Desktop.

---

## 📱 Features

- **Apple Cupertino Design**: Pure dark space-black theme (`#0b0f19`) with frosted glass navigation, hairline borders, and fluid spring check-in physics.
- **Concentric Apple Activity Rings**: Custom vector Canvas painter calculating Overall, Craft, and Vitality percentage arcs in real-time.
- **Daily Habits Matrix**: Filterable by category (`Coding`, `Reading`, `Fitness`, `Mindfulness`, `Hydration`) with target days and check-in rewards (+15 XP).
- **Focus Pomodoro Timer**: Countdown timer awarding +25 XP upon completion.
- **Apple Notes & Mood Tracker**: Daily reflection journal with mood selectors and date tagging.
- **Apple Watch Activity Awards Gallery**: Interactive modal showing 8 milestone medals.
- **$0 Cost-Free Live Sync**: Communicates with the local Node.js server (`/api/sync/:uid`) or your Vercel serverless deployment to maintain 100% two-way sync across Android, Web, and Desktop.

---

## 🚀 Running & Building

### Prerequisites
1. Install [Flutter SDK](https://flutter.dev/docs/get-started/install/windows) (Flutter 3.0+ with Dart 3.0+).
2. Enable Android Debugging / USB Debugging on your phone or launch an Android Emulator.

### Run on Device or Emulator:
```bash
cd android
flutter pub get
flutter run
```

### Build Production APK:
```bash
flutter build apk --release
```
The output APK will be located at:
`android/build/app/outputs/flutter-apk/app-release.apk`

---

## 🌐 Live Sync Setup
1. In the top-right corner of the app, tap the **`○ Offline / ● Synced`** pill.
2. Enter your PC's local IP address (e.g. `http://192.168.8.184:3000`) or your live Vercel URL.
3. Tap **Test & Sync Now** — all habits, XP, levels, and check-ins will synchronize across all your devices instantly!
