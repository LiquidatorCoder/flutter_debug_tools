<h1 align="center">Flutter Debug Tools</h1>

<p align="center">
  <b>A set of interactive, in-app tools for diagnosing UI and performance issues in Flutter apps—no external tooling required.</b>
</p><br>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform" />
  </a>
  <a href="https://pub.dartlang.org/packages/flutter_debug_tools">
    <img src="https://img.shields.io/pub/v/flutter_debug_tools.svg" alt="Pub Package" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/github/license/aagarwal1012/animated-text-kit?color=red" alt="License: MIT" />
  </a>
  <a href="https://www.paypal.me/codenameakshay">
    <img src="https://img.shields.io/badge/Donate-PayPal-00457C?logo=paypal" alt="Donate" />
  </a>
</p><br>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#license">License</a> •
  <a href="#credits">Credits</a> •
  <a href="#bugs-or-requests">Bugs or Requests</a>
</p><br>

---

| ![Demo Animation](https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/demo.gif) | ![Menu Screenshot](https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/image.png) |
| ------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- |
| **Interactive Demo**                                                                                               | **Tools Menu**                                                                                                       |

---

## Features

- **Performance Overlay:**  
  Visualize FPS, frame rendering time, and rasterization metrics over your app’s UI.

- **Device Details Overlay:**  
  Instantly see device-specific information (model, OS version, screen size, and more) directly within your app.

- **Debug Paint / Layout Guides:**  
  Reveal widget boundaries, padding, alignments, and layout constraints with a single toggle.

- **Layer Bounds Display:**  
  Understand how Flutter composes layers by viewing layer boundaries in real-time.

- **Debug Log Overlay:**  
  Keep track of logs without attaching to an external console—logs appear right on top of your running app.

- **Repaint Rainbow:**  
  Easily detect frequent widget repaints. The overlay colors widgets differently each time they repaint, helping identify costly builds.

- **Color Picker:**  
  Tap on any pixel to grab its color value—perfect for UI fine-tuning and design validation.

- **Screen Name Overlay:**  
  Always know which route or screen is currently displayed, useful for debugging navigation flows.

**No special IDEs or separate debug modes required—just integrate and toggle overlays as you run your app.**

---

## Installation

Add the following line to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_debug_tools: ^1.0.0
```

Then, run:

```bash
flutter pub get
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';

void main() {
    // (Optional) Initialize Loggy with the DebugLoggyPrinter to show logs in the Debug Log
    Loggy.initLoggy(logOptions: LogOptions(), logPrinter: DebugLoggyPrinter());

  runApp(MyApp());
}

// Wrap your material app with the `FlutterDebugTools` widget
return FlutterDebugTools(
  builder: (context, showPerformanceOverlay, child) {
    // (Optional) Attach navigatorObserver to observe the screen details
    final DebugNavigatorObserver navigatorObserver = DebugNavigatorObserver();
    return MaterialApp(
      // Control performance overlay using [showPerformanceOverlay]
      showPerformanceOverlay: showPerformanceOverlay,
      home: MyHomePage(),
      // Add `navigatorObservers` to observe the screen details
      navigatorObservers: [navigatorObserver],
    );
  },
);


```

## License

```
MIT License

Copyright (c) 2024 Abhay Maurya

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Credits

This package uses the following open-source packages:

- [Loggy](https://pub.dev/packages/loggy)
- [Shared Preferences](https://pub.dev/packages/shared_preferences)
- [Device Info Plus](https://pub.dev/packages/device_info_plus)

## Bugs or Requests

- For bugs, please [open an issue](https://github.com/LiquidatorCoder/flutter_debug_tools/issues/new?template=bug_report.md).
- For features or enhancements, submit a [feature request](https://github.com/LiquidatorCoder/flutter_debug_tools/issues/new?template=feature_request.md).
- PRs are welcome—contributions help make this tool better!
