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

  static const double _trayWidth = 48;
  static const double _trayHeight = 48;

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
    prefs.getDouble("animationSpeedFactor").then((value) {
      if (value == null) return;
      state.value = state.value.copyWith(animationSpeedFactor: value.clamp(0.25, 2.0));
    });
    prefs.getString("animationCurvePreset").then((value) {
      if (value == null) return;
      state.value = state.value.copyWith(animationCurvePreset: AnimationCurvePreset.fromId(value));
    });
    prefs.getBool("shouldPauseAnimations").then((value) {
      state.value = state.value.copyWith(shouldPauseAnimations: value == true);
    });
    prefs.getBool("shouldDisableAnimations").then((value) {
      state.value = state.value.copyWith(shouldDisableAnimations: value == true);
    });
    prefs.getDouble("animationHighlightSensitivity").then((value) {
      if (value == null) return;
      state.value = state.value.copyWith(animationHighlightSensitivity: value.clamp(5.0, 60.0));
    });
    prefs.getInt("animationHighlightIntervalMs").then((value) {
      if (value == null) return;
      state.value = state.value.copyWith(animationHighlightIntervalMs: value.clamp(60, 400));
    });
    prefs.getInt("animationHighlightDecayMs").then((value) {
      if (value == null) return;
      state.value = state.value.copyWith(animationHighlightDecayMs: value.clamp(150, 1500));
    });
    prefs.getDouble("animationHighlightOpacity").then((value) {
      if (value == null) return;
      state.value = state.value.copyWith(animationHighlightOpacity: value.clamp(0.1, 0.9));
    });
  }

  Future<void> _initDeviceData() async {
    final deviceData = await deviceInfoManager.getDeviceDetails();
    state.value = state.value.copyWith(deviceData: deviceData);

    final shouldRestoreHighlights = await SharedPrefsManager.instance.getBool("shouldShowAnimationHighlights") == true;
    if (!shouldRestoreHighlights) {
      return;
    }

    final reason = _knownUnsafeHighlightReason(deviceData);
    if (reason != null) {
      state.value = state.value.copyWith(
        shouldShowAnimationHighlights: false,
        shouldUseAnimationHighlightCompatibility: true,
        animationHighlightUnavailableReason: reason,
      );
      return;
    }

    state.value = state.value.copyWith(
      shouldShowAnimationHighlights: true,
      shouldUseAnimationHighlightCompatibility: false,
      animationHighlightUnavailableReason: null,
    );
  }

  String? _knownUnsafeHighlightReason(Map<String, dynamic> data) {
    final sdk = int.tryParse((data['SDK Version']?.toString() ?? '').trim());

    if (sdk != null && sdk <= 31) {
      return 'Using compatibility highlight mode on Android 12 and below to avoid a known Impeller capture crash.';
    }

    return null;
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
                  right: -10,
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
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                child: Image(
                  image: AssetImage(
                    'assets/images/icon.png',
                    package: 'flutter_debug_tools',
                  ),
                  width: 34,
                  height: 34,
                ),
              )),
          const ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: Image(
              image: AssetImage(
                'assets/images/icon.png',
                package: 'flutter_debug_tools',
              ),
              width: 34,
              height: 34,
            ),
          ),
        ],
      ),
    );
  }
}
