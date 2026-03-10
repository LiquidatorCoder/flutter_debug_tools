import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_debug_tools/src/debug_log_store.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/view/debug_device_details_dialog.dart';
import 'package:flutter_debug_tools/src/view/debug_indicator.dart';
import 'package:flutter_debug_tools/src/view/debug_logs_viewer.dart';
import 'package:flutter_debug_tools/src/view/debug_screen_details_widget.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel.dart';
import 'package:flutter_debug_tools/src/view/pixel_color_inspector.dart';
import 'package:flutter_debug_tools/src/view/render_box_inspector.dart';

/// FlutterLens overlays debugging tools over its [child].
class FlutterLens extends StatefulWidget {
  final Widget Function(BuildContext context, bool value, Widget? child) builder;
  final Widget? child;
  final bool isEnabled;

  const FlutterLens({
    super.key,
    this.child,
    this.isEnabled = kDebugMode,
    required this.builder,
  });

  @override
  State<FlutterLens> createState() => _FlutterLensState();
}

class _FlutterLensState extends State<FlutterLens> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DebugLogCapture.install();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (state.value.shouldShowLogsScreen) {
      _toggleLogs();
      return true;
    }

    if (state.value.shouldShowDeviceDetails) {
      _toggleDeviceDetails();
      return true;
    }

    return false;
  }

  void _toggleDialog() => state.value = state.value.copyWith(shouldShowToolsPanel: !state.value.shouldShowToolsPanel);
  void _toggleLogs() => state.value = state.value.copyWith(shouldShowLogsScreen: !state.value.shouldShowLogsScreen);
  void _toggleColorPicker() =>
      state.value = state.value.copyWith(shouldShowColorPicker: !state.value.shouldShowColorPicker);
  void _toggleDeviceDetails() =>
      state.value = state.value.copyWith(shouldShowDeviceDetails: !state.value.shouldShowDeviceDetails);

  String colorToHexString(Color color, {bool withAlpha = false}) {
    String channelToHex(double value) => (value * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');

    final a = channelToHex(color.a);
    final r = channelToHex(color.r);
    final g = channelToHex(color.g);
    final b = channelToHex(color.b);

    if (withAlpha) {
      return '#$a$r$g$b';
    }

    return '#$r$g$b';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return widget.builder(context, false, widget.child);
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<DebugToolsState>(
        valueListenable: state,
        builder: (context, value, child) {
          return PopScope(
            canPop: !value.shouldShowLogsScreen,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && value.shouldShowLogsScreen) {
                _toggleLogs();
              }
            },
            child: Stack(
              children: [
                if (value.shouldShowColorPicker)
                  PixelColorInspector(
                    child: (value.shouldShowRenderBoxDetails)
                        ? RenderBoxInspector(child: widget.builder(context, value.shouldShowPerformanceOverlay, child))
                        : widget.builder(context, value.shouldShowPerformanceOverlay, child),
                    onColorPicked: (val) {
                      state.value = state.value.copyWith(currentColor: val);
                      _toggleColorPicker();
                      _toggleDialog();
                    },
                  )
                else
                  (value.shouldShowRenderBoxDetails)
                      ? RenderBoxInspector(child: widget.builder(context, value.shouldShowPerformanceOverlay, child))
                      : widget.builder(context, value.shouldShowPerformanceOverlay, child),
                if (value.shouldShowToolsIndicator) DebugIndicator(toggleTools: _toggleDialog),
                if (value.shouldShowToolsPanel)
                  DebugToolsPanel(
                    color: value.currentColor,
                    onClose: _toggleDialog,
                    toggleLogs: _toggleLogs,
                    toggleColorPicker: () {
                      _toggleColorPicker();
                      _toggleDialog();
                    },
                    clearColor: () {
                      Clipboard.setData(ClipboardData(text: colorToHexString(value.currentColor ?? Colors.white)));
                      state.value = state.value.clearColor();
                      _toggleDialog();
                    },
                    toggleDeviceDetails: _toggleDeviceDetails,
                  ),
                if (value.shouldShowScreenName)
                  DebugScreenDetailsWidget(
                    screenName: value.currentScreen ?? '',
                  ),
                if (value.shouldShowDeviceDetails)
                  DebugDeviceDetailsDialog(
                    onTap: _toggleDeviceDetails,
                  ),
                if (value.shouldShowLogsScreen) DebugLogsViewer(onTap: _toggleLogs)
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
