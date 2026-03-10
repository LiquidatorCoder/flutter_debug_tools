import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/utils/device_info_manager.dart';
import 'package:flutter_debug_tools/src/utils/shared_prefs_manager.dart';

/// Draggable edge tray that opens debug tools.
class DebugIndicator extends StatefulWidget {
  final VoidCallback toggleTools;

  const DebugIndicator({
    super.key,
    required this.toggleTools,
  });

  @override
  State<DebugIndicator> createState() => _DebugIndicatorState();
}

class _DebugIndicatorState extends State<DebugIndicator> {
  final DeviceInfoManager deviceInfoManager = DeviceInfoManager.instance;

  static const double _trayWidth = 34;
  static const double _trayHeight = 44;
  static const double _edgeMargin = 2;

  double? _trayTop;
  bool _trayPressed = false;

  @override
  void initState() {
    super.initState();
    _initValues();
    _initDeviceData();
  }

  void _initValues() {
    final prefs = SharedPrefsManager.instance;
    prefs.getBool("debugPaintSizeEnabled").then((value) {
      debugPaintSizeEnabled = value == true;
    });
    prefs.getBool("debugRepaintTextRainbowEnabled").then((value) {
      debugRepaintTextRainbowEnabled = value == true;
    });
    prefs.getBool("showPerformanceOverlay").then((value) {
      state.value = state.value.copyWith(shouldShowPerformanceOverlay: value == true);
    });
    prefs.getBool("shouldShowScreenName").then((value) {
      state.value = state.value.copyWith(shouldShowScreenName: value == true);
    });
  }

  Future<void> _initDeviceData() async {
    final deviceData = await deviceInfoManager.getDeviceDetails();
    state.value = state.value.copyWith(deviceData: deviceData);
  }

  double _clampTop(double top, double maxHeight) {
    const double minTop = 12;
    final double maxTop = (maxHeight - _trayHeight - 12).clamp(minTop, maxHeight);
    return top.clamp(minTop, maxTop);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _trayTop ??= _clampTop(
              constraints.maxHeight * 0.45 - (_trayHeight / 2),
              constraints.maxHeight,
            );

            return Stack(
              children: [
                Positioned(
                  right: -_edgeMargin,
                  top: _trayTop,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 20, end: 0),
                    duration: const Duration(milliseconds: 500),
                    curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: 1 - (value / 20),
                        child: Transform.translate(
                          offset: Offset(value + (_trayPressed ? 3 : 0), 0),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: widget.toggleTools,
                      onTapDown: (_) => setState(() => _trayPressed = true),
                      onTapUp: (_) => setState(() => _trayPressed = false),
                      onTapCancel: () => setState(() => _trayPressed = false),
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _trayTop = _clampTop(
                            (_trayTop ?? 0) + details.delta.dy,
                            constraints.maxHeight,
                          );
                        });
                      },
                      child: const _DebugTray(width: _trayWidth, height: _trayHeight),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DebugTray extends StatelessWidget {
  final double width;
  final double height;

  const _DebugTray({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    const LinearGradient accent = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF7A250), Color(0xFFE24A79), Color(0xFF5A3386)],
    );

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
        child: Container(
          width: width,
          decoration: const BoxDecoration(
            gradient: accent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            border: Border(
              left: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.2)),
              top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.2)),
              bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.2)),
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.5),
                blurRadius: 24,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Icon(
            Icons.bug_report,
            size: 13,
            color: Color.fromRGBO(255, 255, 255, 0.85),
          ),
        ),
      ),
    );
  }
}
