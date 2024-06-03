<h1 align="center">Flutter Debug Tools</h1>

<p align="center">A set of tools to help find and debug UI or performance issues from the Flutter app itself. Works with any Flutter app.
</p><br>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter"
      alt="Platform" />
  </a>
  <a href="https://pub.dartlang.org/packages/flutter_debug_tools">
    <img src="https://img.shields.io/pub/v/flutter_debug_tools.svg"
      alt="Pub Package" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/github/license/aagarwal1012/animated-text-kit?color=red"
      alt="License: MIT" />
  </a>
  <a href="https://www.paypal.me/codenameakshay">
    <img src="https://img.shields.io/badge/Donate-PayPal-00457C?logo=paypal"
      alt="Donate" />
  </a>
</p><br>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#license">License</a> •
  <a href="#credits">Credits</a>
</p><br>

| ![Example](https://raw.githubusercontent.com/LiquidatorCoder/flutter_debug_tools/main/screenshots/demo.gif) |
| ----------------------------------------------------------------------------------------------------------- |
| **Example app**                                                                                             |

## Key Features

- **Performance Overlay**: A widget that overlays your app and shows performance metrics such as FPS, frame rasterizer, and frame build time.

- **Device Details**: A widget that overlays your app and shows the device details such as device name, model, version, and more.

- **Debug Paint**: A widget that overlays your app and shows the visual layout of the widgets.

- **Layer Bounds**: A widget that overlays your app and shows the layer bounds of the widgets.

- **Debug Log**: A widget that overlays your app and shows the logs from the app.

- **Repaint Rainbow**: A widget that overlays your app and shows the repaint boundaries of the widgets, and the color changes when the widget is repainted.

- **Color Picker**: A widget that overlays your app and allows you to pick a color from the screen.

- **Screen Name**: A widget that overlays your app and shows the path of the current screen.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_debug_tools: ^0.0.3+1
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';

void main() {
    // (Optional) Initialize Loggy with the DebugLoggyPrinter to show logs in the Debug Log
    Loggy.initLoggy(logOptions: logOptions, logPrinter: DebugLoggyPrinter());

  runApp(MyApp());
}

// Wrap your material app with the `FlutterDebugTools` widget
return FlutterDebugTools(
    builder: (context, value, child) {
      // (Optional) Attach navigatorObserver to observe the screen details
        final DebugNavigatorObserver navigatorObserver = DebugNavigatorObserver();
        return MaterialApp(
            // And pass the value to the `showPerformanceOverlay` property
            showPerformanceOverlay: value,
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

This software uses the following open source packages:

- [Loggy](https://pub.dev/packages/loggy)
- [Shared Preferences](https://pub.dev/packages/shared_preferences)
- [Device Info Plus](https://pub.dev/packages/device_info_plus)

## Bugs or Requests

If you encounter any problems feel free to open an [issue](https://github.com/LiquidatorCoder/flutter_debug_tools/issues/new?template=bug_report.md). If you feel the library is missing a feature, please raise a [ticket](https://github.com/LiquidatorCoder/flutter_debug_tools/issues/new?template=feature_request.md) on GitHub and I'll look into it. Pull request are also welcome.
