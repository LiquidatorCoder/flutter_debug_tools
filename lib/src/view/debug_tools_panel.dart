import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/utils/shared_prefs_manager.dart';

/// DebugToolsPanel is a widget that displays a dialog containing debugging options.
/// Allows toggling of various debug modes and viewing of logs.
class DebugToolsPanel extends StatelessWidget {
  final Color? color;
  final VoidCallback onClose;
  final VoidCallback toggleLogs;
  final VoidCallback toggleColorPicker;

  const DebugToolsPanel({
    Key? key,
    this.color,
    required this.onClose,
    required this.toggleLogs,
    required this.toggleColorPicker,
  }) : super(key: key);

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

  void _toggleDebugPaint() {
    debugPaintSizeEnabled = !debugPaintSizeEnabled;
    SharedPrefsManager.instance.setBool("debugPaintSizeEnabled", debugPaintSizeEnabled);
  }

  void _toggleLayerBounds() {
    debugPaintLayerBordersEnabled = !debugPaintLayerBordersEnabled;
    SharedPrefsManager.instance.setBool("debugPaintLayerBordersEnabled", debugPaintLayerBordersEnabled);
  }

  void _toggleRepaintRainbow() {
    debugRepaintTextRainbowEnabled = !debugRepaintTextRainbowEnabled;
    SharedPrefsManager.instance.setBool("debugRepaintTextRainbowEnabled", debugRepaintTextRainbowEnabled);
  }

  void _togglePerfOverlay() {
    state.value = state.value.copyWith(shouldShowPerformanceOverlay: !state.value.shouldShowPerformanceOverlay);
    SharedPrefsManager.instance.setBool("showPerformanceOverlay", state.value.shouldShowPerformanceOverlay);
  }

  Widget _buildIcon(
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              height: 48,
              width: 48,
              child: Center(
                child: Icon(
                  icon,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            SizedBox(
              width: 48,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Dialog(
            alignment: Alignment.topCenter,
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(500),
                      color: Colors.white,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      child: Text(
                        "Flutter Tools",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (color != null)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(500),
                        color: color ?? Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        child: Text(
                          colorToHexString(color ?? Colors.white),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: (color ?? Colors.white).computeLuminance() > 0.5 ? Colors.black : Colors.white),
                        ),
                      ),
                    ),
                  if (color != null) const SizedBox(height: 16),
                  Wrap(
                    children: [
                      _buildIcon('Debug Paint', Icons.grid_3x3, _toggleDebugPaint),
                      _buildIcon('Layer Bounds', Icons.grid_on, _toggleLayerBounds),
                      _buildIcon('Repaint Rainbow', Icons.format_paint, _toggleRepaintRainbow),
                      _buildIcon('Debug Logs', Icons.text_snippet, toggleLogs),
                      _buildIcon('Perf Overlay', Icons.bar_chart, _togglePerfOverlay),
                      _buildIcon('Color Picker', Icons.colorize, toggleColorPicker),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
