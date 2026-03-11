import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_debug_tools/src/view/flutter_lens_theme.dart';

class DebugFrameTimingHud extends StatefulWidget {
  const DebugFrameTimingHud({
    super.key,
    required this.child,
    required this.isEnabled,
  });

  final Widget child;
  final bool isEnabled;

  @override
  State<DebugFrameTimingHud> createState() => _DebugFrameTimingHudState();
}

class _DebugFrameTimingHudState extends State<DebugFrameTimingHud> {
  static const int _window = 45;

  final ListQueue<double> _frameMs = ListQueue<double>(_window);
  late final TimingsCallback _timingsCallback;
  bool _registered = false;
  double _avgMs = 0;
  double _worstMs = 0;

  @override
  void initState() {
    super.initState();
    _timingsCallback = _onTimings;
    _syncRegistration();
  }

  @override
  void didUpdateWidget(covariant DebugFrameTimingHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnabled != widget.isEnabled) {
      _syncRegistration();
    }
  }

  @override
  void dispose() {
    if (_registered) {
      SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
    }
    super.dispose();
  }

  void _syncRegistration() {
    if (_registered) {
      SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
      _registered = false;
    }

    if (!widget.isEnabled) {
      setState(() {
        _frameMs.clear();
        _avgMs = 0;
        _worstMs = 0;
      });
      return;
    }

    SchedulerBinding.instance.addTimingsCallback(_timingsCallback);
    _registered = true;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted || !widget.isEnabled || timings.isEmpty) return;

    for (final timing in timings) {
      final ms = timing.totalSpan.inMicroseconds / 1000.0;
      if (_frameMs.length == _window) {
        _frameMs.removeFirst();
      }
      _frameMs.add(ms);
    }

    double sum = 0;
    double worst = 0;
    for (final value in _frameMs) {
      sum += value;
      if (value > worst) worst = value;
    }

    setState(() {
      _avgMs = _frameMs.isEmpty ? 0 : sum / _frameMs.length;
      _worstMs = worst;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fps = _avgMs <= 0 ? 0 : (1000 / _avgMs).clamp(0, 120);
    final janky = _worstMs > 20;
    final Color accent = janky ? const Color(0xFFE24A79) : const Color(0xFF4ADE80);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.isEnabled)
          IgnorePointer(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.only(left: 14, top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xCC12131A),
                    border: Border.all(color: accent.withValues(alpha: 0.65)),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: flutterLensFontFamily,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('FPS ${fps.toStringAsFixed(0)}'),
                        const SizedBox(width: 10),
                        Text('AVG ${_avgMs.toStringAsFixed(1)}ms'),
                        const SizedBox(width: 10),
                        Text('MAX ${_worstMs.toStringAsFixed(1)}ms'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
