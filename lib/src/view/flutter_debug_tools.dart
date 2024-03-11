import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
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
  const FlutterDebugTools({Key? key, required this.builder}) : super(key: key);

  void _toggleIndicator() => state.value = state.value.copyWith(
      shouldShowToolsIndicator: !state.value.shouldShowToolsIndicator);
  void _toggleDialog() => state.value = state.value
      .copyWith(shouldShowToolsPanel: !state.value.shouldShowToolsPanel);
  void _toggleLogs() => state.value = state.value
      .copyWith(shouldShowLogsScreen: !state.value.shouldShowLogsScreen);
  void _toggleColorPicker() => state.value = state.value
      .copyWith(shouldShowColorPicker: !state.value.shouldShowColorPicker);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SafeArea(
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
                      state.value = state.value.copyWith(currentColor: null);
                      _toggleDialog();
                    },
                    toggleLogs: _toggleLogs,
                    toggleColorPicker: () {
                      _toggleColorPicker();
                      _toggleDialog();
                    },
                  ),
                // Logs viewer
                if (value.shouldShowLogsScreen)
                  DebugLogsViewer(onTap: _toggleLogs)
              ],
            );
          },
        ),
      ),
    );
  }
}
