import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/view/debug_device_details_dialog.dart';
import 'package:flutter_debug_tools/src/view/debug_indicator.dart';
import 'package:flutter_debug_tools/src/view/debug_logs_viewer.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel.dart';
import 'package:flutter_debug_tools/src/view/pixel_color_inspector.dart';

/// FlutterDebugTools is a widget that overlays debugging tools over its [child].
/// It provides access to various debugging functionalities such as enabling
/// debug paint, showing performance overlays, and viewing logs.
class FlutterDebugTools extends StatelessWidget {
  final Widget Function(BuildContext context, bool value, Widget? child)
      builder;
  final Widget? child;
  const FlutterDebugTools({Key? key, this.child, required this.builder})
      : super(key: key);

  void _toggleIndicator() => state.value = state.value.copyWith(
      shouldShowToolsIndicator: !state.value.shouldShowToolsIndicator);
  void _toggleDialog() => state.value = state.value
      .copyWith(shouldShowToolsPanel: !state.value.shouldShowToolsPanel);
  void _toggleLogs() => state.value = state.value
      .copyWith(shouldShowLogsScreen: !state.value.shouldShowLogsScreen);
  void _toggleColorPicker() => state.value = state.value
      .copyWith(shouldShowColorPicker: !state.value.shouldShowColorPicker);
  void _toggleDeviceDetails() => state.value = state.value
      .copyWith(shouldShowDeviceDetails: !state.value.shouldShowDeviceDetails);

  String colorToHexString(Color color, {bool withAlpha = false}) {
    final a = color.alpha.toRadixString(16).padLeft(2, '0');
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');

    if (withAlpha) {
      return '#$a$r$g$b';
    }

    return '#$r$g$b';
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return builder(context, false, child);
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<DebugToolsState>(
        valueListenable: state,
        builder: (context, value, child) {
          return Stack(
            children: [
              if (value.shouldShowColorPicker)
                // Color picker UI
                PixelColorInspector(
                  child: builder(
                      context, value.shouldShowPerformanceOverlay, child),
                  onColorPicked: (val) {
                    state.value = state.value.copyWith(currentColor: val);
                    _toggleColorPicker();
                    _toggleDialog();
                  },
                )
              else
                builder(context, value.shouldShowPerformanceOverlay, child),
              // Indicator to show Flutter screens
              if (value.shouldShowToolsIndicator)
                DebugIndicator(
                    toggleTools: _toggleDialog,
                    toggleIndicator: _toggleIndicator),
              // Tools panel for debugging tools
              if (value.shouldShowToolsPanel)
                DebugToolsPanel(
                  color: value.currentColor,
                  onClose: () {
                    _toggleDialog();
                  },
                  toggleLogs: _toggleLogs,
                  toggleColorPicker: () {
                    _toggleColorPicker();
                    _toggleDialog();
                  },
                  clearColor: () {
                    Clipboard.setData(ClipboardData(
                        text: colorToHexString(
                            value.currentColor ?? Colors.white)));
                    state.value = state.value.clearColor();
                    _toggleDialog();
                  },
                  toggleDeviceDetails: () {
                    _toggleDialog();
                    _toggleDeviceDetails();
                  },
                ),
              // Device details
              if (value.shouldShowDeviceDetails)
                DebugDeviceDetailsDialog(
                  onTap: _toggleDeviceDetails,
                ),
              // Logs viewer
              if (value.shouldShowLogsScreen)
                DebugLogsViewer(onTap: _toggleLogs)
            ],
          );
        },
        child: child,
      ),
    );
  }
}
