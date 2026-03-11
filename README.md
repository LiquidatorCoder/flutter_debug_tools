![FlutterLens](https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/image.png)

<p align="center">
  <b>In-app debug tools for Flutter UI, rendering, logs, navigation, and device diagnostics - no context switching required.</b>
</p>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform" />
  </a>
  <a href="https://pub.dev/packages/flutter_debug_tools">
    <img src="https://img.shields.io/pub/v/flutter_debug_tools.svg" alt="Pub Package" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-red" alt="License: MIT" />
  </a>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-debug-logs-how-it-works">Debug Logs</a> •
  <a href="#-tips">Tips</a> •
  <a href="#-license">License</a>
</p>

---

| Screenshots                                                                                                  |                                                                                                              |                                                                                                              |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| <img src="https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/flow/1.png" alt="Flow 1" width="360" height="780" /> | <img src="https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/flow/3.png" alt="Flow 3" width="360" height="780" /> | <img src="https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/flow/5.png" alt="Flow 5" width="360" height="780" /> |
| 🧲 **Edge tray launcher** docked to the right side; draggable and always accessible.                         | 📋 **Bottom sheet tools grid** with active/inactive visual states and quick toggles.                         | 🎨 **Color result card** showing selected color in HEX, RGB, and HSL with copy action.                       |
| <img src="https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/flow/2.png" alt="Flow 2" width="360" height="780" /> | <img src="https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/flow/4.png" alt="Flow 4" width="360" height="780" /> | <img src="https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/flow/6.png" alt="Flow 6" width="360" height="780" /> |
| 🧾 **Version ticker** displaying app, FlutterLens, Flutter, Dart, and build mode details.                    | 📱 **In-app debug logs** to inspect console logs inside the running app.                                     | ⚡ **Device details** to quickly check and share device details.                                             |

---

## ✨ Features

- 🧭 **Screen Name Overlay**: See the active route/screen while navigating.
- 📋 **Debug Logs Viewer**: Capture and inspect console logs inside the running app.
- 📱 **Device Details**: Inspect model, OS, screen metrics, and hardware info in-app.
- 🎯 **Color Picker**: Pick any on-screen pixel color quickly.
- 🧱 **Debug Paint / Layout Insights**: Visualize layout boundaries and spacing behavior.
- 🌈 **Repaint Rainbow**: Spot frequent repaints to detect expensive widgets.
- 🎛️ **Animation Toolbox**: Control animation speed, pause, reduce motion, and inspect animated regions.
- ⚡ **Performance Overlay Toggle**: Enable Flutter performance overlay directly from the panel.
- 🧲 **Edge Tray Launcher**: Open FlutterLens from a draggable edge tray.
- 🧾 **Version Ticker**: Live ticker for app/build/flutter/dart/FlutterLens versions.
- 🎨 **Picked Color Card**: View HEX/RGB/HSL + copy from the panel.
- 💾 **Sticky Debug Toggles**: Core flags are persisted across launches.

### 🧰 Tool-by-tool quick map

- `Debug Paint` → toggles `debugPaintSizeEnabled`
- `Size Info` → enables render box inspector overlay
- `Repaint Rainbow` → toggles `debugRepaintTextRainbowEnabled`
- `Debug Logs` → opens in-app logs viewer
- `Perf Overlay` → toggles `showPerformanceOverlay`
- `Color Picker` → pixel pick + color card/copy flow
- `Device Details` → opens device info sheet
- `Screen Name` → route name overlay (with `DebugNavigatorObserver`)
- `Animation Toolbox` → animation speed/pause/disable/highlight controls

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_debug_tools: ^2.0.0
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';

Future<void> main() async {
  await DebugLogCapture.runApp(() async {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navigatorObserver = DebugNavigatorObserver();

    return FlutterLens(
      builder: (context, showPerformanceOverlay, child) {
        return MaterialApp(
          title: 'FlutterLens Demo',
          showPerformanceOverlay: showPerformanceOverlay,
          navigatorObservers: [navigatorObserver],
          home: const Placeholder(),
        );
      },
    );
  }
}
```

### 🧩 Minimal integration (without log zone wrapper)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterLens(
      builder: (context, showPerformanceOverlay, child) {
        return MaterialApp(
          showPerformanceOverlay: showPerformanceOverlay,
          home: const Placeholder(),
        );
      },
    );
  }
}
```

### 🎛️ Disable in non-debug environments

```dart
FlutterLens(
  isEnabled: kDebugMode,
  builder: (context, showPerformanceOverlay, child) {
    return MaterialApp(
      showPerformanceOverlay: showPerformanceOverlay,
      home: const HomeScreen(),
    );
  },
)
```

---

## 🧾 Debug Logs (How It Works)

- ✅ Captures Dart-side console logs (including `print` output in the wrapped zone)
- ✅ Captures framework/platform error callbacks and shows them in the logs viewer
- ✅ Lets you filter logs by level (`All`, `Info`, `Warn`, `Error`, `Debug`)
- ✅ Tap any log row to copy it to clipboard

If you already use another logger, you can still use it; FlutterLens will continue showing captured console/error output in the viewer.

### 🔎 What gets captured

- `print(...)` output (inside `DebugLogCapture.runApp` zone)
- `FlutterError.onError`
- `PlatformDispatcher.instance.onError`
- uncaught zoned async exceptions

### 📚 Public logging APIs

- `DebugLogCapture.install()`
- `DebugLogCapture.runApp(() async { ... })`
- `DebugLogStore.instance.add(...)`
- `DebugLogStore.instance.clear()`

---

## 🧭 Navigation integration

To populate route names in the `Screen Name` overlay, attach `DebugNavigatorObserver`:

```dart
MaterialApp(
  navigatorObservers: [DebugNavigatorObserver()],
  home: const HomeScreen(),
)
```

---

## 🖱️ Panel interactions

- Swipe down on the panel to dismiss.
- Tap outside the panel to dismiss.
- Drag the right-edge tray up/down to reposition.
- Tap the tray to open FlutterLens.

---

## 💡 Tips

- Use FlutterLens only in debug/dev environments.
- Add `DebugNavigatorObserver` for better route visibility in overlays.
- Keep an eye on `Repaint Rainbow` + `Performance Overlay` together for quick perf diagnosis.
- If Dart/Flutter versions show fallback values, pass build-time dart-defines for those keys.

---

## 🙌 Credits

Built with:

- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [device_info_plus](https://pub.dev/packages/device_info_plus)

---

## 🐞 Bugs or Requests

- Bug report: [Open issue](https://github.com/LiquidatorCoder/flutter_debug_tools/issues/new?template=bug_report.md)
- Feature request: [Open request](https://github.com/LiquidatorCoder/flutter_debug_tools/issues/new?template=feature_request.md)
- PRs are welcome! 🎉

---

## 📄 License

MIT License
