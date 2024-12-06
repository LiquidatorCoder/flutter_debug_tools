import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/utils/device_info_manager.dart';
import 'package:flutter_debug_tools/src/utils/shared_prefs_manager.dart';

/// DebugIndicator is a widget that shows an interactive debug icon.
/// Tapping on the icon toggles the visibility of the debugging tools panel.
class DebugIndicator extends StatefulWidget {
  final VoidCallback toggleTools;
  final VoidCallback toggleIndicator;
  const DebugIndicator({super.key, required this.toggleTools, required this.toggleIndicator});

  @override
  State<DebugIndicator> createState() => _DebugIndicatorState();
}

class _DebugIndicatorState extends State<DebugIndicator> with SingleTickerProviderStateMixin {
  final deviceInfoManager = DeviceInfoManager.instance;
  late AnimationController _controller;
  Timer? _timer;
  bool _showDot = false;

  @override
  void initState() {
    super.initState();
    _initValues();
    _initDeviceData();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    Tween<double>(begin: 1.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showDot = true;
          });
        }
      });

    // Start the animation after 3 seconds
    _timer = Timer(const Duration(seconds: 3), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RepaintBoundary(
        child: Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: widget.toggleTools,
            onLongPress: widget.toggleIndicator,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(8.0),
              child: _showDot
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.shade800, width: 1),
                      ),
                    )
                  : Transform.scale(
                      alignment: Alignment.topRight,
                      scaleY: 1 - _controller.value / 1.9,
                      scaleX: 1 - _controller.value / 1.2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          border: Border.all(color: Colors.blue.shade800, width: 1),
                          borderRadius: BorderRadius.circular(4 + _controller.value * 200),
                        ),
                        child: Opacity(
                          opacity: 1 - _controller.value,
                          child: const Text(
                            'FLUTTER',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
