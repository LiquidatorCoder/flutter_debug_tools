import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class DebugAnimationHighlightCompatOverlay extends StatefulWidget {
  const DebugAnimationHighlightCompatOverlay({
    super.key,
    required this.child,
    required this.isEnabled,
    required this.opacity,
  });

  final Widget child;
  final bool isEnabled;
  final double opacity;

  @override
  State<DebugAnimationHighlightCompatOverlay> createState() => _DebugAnimationHighlightCompatOverlayState();
}

class _DebugAnimationHighlightCompatOverlayState extends State<DebugAnimationHighlightCompatOverlay> {
  double _activity = 0.0;
  Timer? _decayTimer;
  late final TimingsCallback _timingsCallback;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _timingsCallback = _onTimings;
    _syncRegistration();
  }

  @override
  void didUpdateWidget(covariant DebugAnimationHighlightCompatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnabled != widget.isEnabled) {
      _syncRegistration();
    }
  }

  @override
  void dispose() {
    if (_isRegistered) {
      SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
      _isRegistered = false;
    }
    _decayTimer?.cancel();
    super.dispose();
  }

  void _syncRegistration() {
    if (_isRegistered) {
      SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
      _isRegistered = false;
    }
    _decayTimer?.cancel();

    if (!widget.isEnabled) {
      if (_activity != 0.0) {
        setState(() => _activity = 0.0);
      }
      return;
    }

    SchedulerBinding.instance.addTimingsCallback(_timingsCallback);
    _isRegistered = true;
    _decayTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      if (_activity <= 0.01) {
        if (_activity != 0.0) {
          setState(() => _activity = 0.0);
        }
        return;
      }
      setState(() {
        _activity = (_activity - 0.08).clamp(0.0, 1.0);
      });
    });
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted || !widget.isEnabled || timings.isEmpty) return;

    double peak = _activity;
    for (final timing in timings) {
      final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
      final normalized = (totalMs / 16.67).clamp(0.0, 2.0) / 2.0;
      if (normalized > peak) peak = normalized;
    }

    final next = peak < 0.12 ? 0.12 : peak;
    if ((next - _activity).abs() > 0.01) {
      setState(() {
        _activity = next.clamp(0.0, 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.isEnabled)
          IgnorePointer(
            child: CustomPaint(
              painter: _ActivityPainter(
                activity: _activity,
                opacity: widget.opacity,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityPainter extends CustomPainter {
  const _ActivityPainter({required this.activity, required this.opacity});

  final double activity;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (activity <= 0.01) return;

    final topRight = Rect.fromLTWH(size.width - 78, 14, 64, 22);
    final indicator = Paint()..color = const Color(0xFFE24A79).withValues(alpha: (0.35 + activity * 0.6) * opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(topRight, const Radius.circular(999)),
      indicator,
    );

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF7A250).withValues(alpha: activity * opacity * 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.35));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
  }

  @override
  bool shouldRepaint(covariant _ActivityPainter oldDelegate) {
    return oldDelegate.activity != activity || oldDelegate.opacity != opacity;
  }
}
