## 2.0.3

- **UI/UX Improvements:** Refined FlutterLens panel, logs viewer, and related debug views for better layout and usability.
- **Bug Fixes:** Fixed color overflow and marquee behavior issues in debug UI flows.
- **Visual Refresh:** Updated tool sheet/tray icon, fonts, screenshots, and image assets.
- **Documentation:** Refreshed README content and image descriptions.

## 2.0.2

- **Static Analysis Fix:** Added an explicit return type to `RenderBoxInspector.show` to satisfy `lints_core` missing type annotation checks.
- **Dependency Updates:** Upgraded `device_info_plus` to `^12.3.0`, `package_info_plus` to `^9.0.0`, and `shared_preferences` to `^2.5.4` for latest supported compatibility.

## 2.0.1

- **README Fix:** Switched branding and flow screenshots to absolute GitHub raw URLs so images render reliably on pub.dev.

## 2.0.0

- **FlutterLens Rebrand (Breaking):** Public widget API renamed from `FlutterDebugTools` to `FlutterLens`.
- **New Debug Panel UI:** Rebuilt tools panel as a modern draggable bottom sheet with:
  - frosted/glass styling
  - active state gradients
  - improved spacing and hierarchy
  - swipe-down-to-dismiss interaction
- **New Edge Tray Launcher:** Replaced old floating control with a draggable right-edge tray tab for quicker access.
- **Enhanced Color Picker Result:** Added rich color card with swatch, HEX/RGB/HSL details, and copy affordance.
- **Version Ticker:** Added animated ticker row to show app/build/runtime metadata (App, FlutterLens, Flutter, Dart, Build).
- **In-App Logs Upgrade:** Integrated `DebugLogStore` + `DebugLogCapture` pipeline for improved log capture/filtering flow.
- **Logging Dependency Cleanup:** Removed `loggy` dependency in favor of built-in FlutterLens log capture/store APIs.
- **Documentation Refresh:** Updated README with FlutterLens branding, expanded usage, screenshots flow, and feature guides.
- **Dependencies:** Added `package_info_plus` for runtime app version reporting in ticker.

## 1.0.0

- **First stable release**  
  Introducing a polished and more reliable toolset for in-app debugging and performance analysis.

## 0.0.5

- **Dependency Upgrade:** Updated `device_info_plus` to version `11.1.1` for improved device information support and compatibility.

## 0.0.4

- **New Feature:** Added a "Size Info" tool to visualize and debug layout dimensions directly in the app.

## 0.0.3

- **New Feature:** Introduced screen details overlay, allowing you to quickly identify which screen (route) is currently being displayed.

## 0.0.2

- **New Feature:** Added a device details overlay, providing instant insights into the device model, OS version, and other environmental information.

## 0.0.1

- **Initial Release:**  
  Kickstarted the project with a suite of six in-app debugging tools, including:

  - **Debug Paint:** Visualize widget boundaries, padding, and layout.
  - **Performance Overlay:** Monitor FPS, frame render time, and rasterization.
  - **Layer Bounds:** Identify how widgets are composed into layers.
  - **Debug Log:** View logs right in the app, without attaching external tooling.
  - **Repaint Rainbow:** Detect frequent rebuilds by highlighting repaint regions with changing colors.
  - **Color Picker:** Grab color values directly from UI elements.

  Supports both Android and iOS for on-device debugging, without the need for separate environments or complex setup.
