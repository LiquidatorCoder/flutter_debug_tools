import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DebugAnimationHighlightOverlay extends StatefulWidget {
  const DebugAnimationHighlightOverlay({
    super.key,
    required this.child,
    required this.isEnabled,
    required this.sensitivity,
    required this.sampleInterval,
    required this.decayDuration,
    required this.opacity,
    this.onUnavailable,
  });

  final Widget child;
  final bool isEnabled;
  final double sensitivity;
  final Duration sampleInterval;
  final Duration decayDuration;
  final double opacity;
  final ValueChanged<String>? onUnavailable;

  @override
  State<DebugAnimationHighlightOverlay> createState() => _DebugAnimationHighlightOverlayState();
}

class _DebugAnimationHighlightOverlayState extends State<DebugAnimationHighlightOverlay> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  static const double _capturePixelRatio = 1.0;

  Timer? _sampleTimer;
  bool _isCapturing = false;
  DateTime? _lastSampleAt;
  Uint8List? _previousFrameBytes;
  int _previousFrameWidth = 0;
  int _previousFrameHeight = 0;
  Map<int, double> _heatByCell = <int, double>{};
  int _gridColumns = 0;
  int _gridRows = 0;
  bool _reportedUnavailable = false;

  @override
  void initState() {
    super.initState();
    _configureSampling();
  }

  @override
  void didUpdateWidget(covariant DebugAnimationHighlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnabled != widget.isEnabled || oldWidget.sampleInterval != widget.sampleInterval) {
      _configureSampling();
    }
  }

  @override
  void dispose() {
    _sampleTimer?.cancel();
    super.dispose();
  }

  void _configureSampling() {
    _sampleTimer?.cancel();

    if (!widget.isEnabled) {
      _reportedUnavailable = false;
      _lastSampleAt = null;
      if (_heatByCell.isNotEmpty || _previousFrameBytes != null) {
        setState(() {
          _heatByCell = <int, double>{};
          _previousFrameBytes = null;
          _previousFrameWidth = 0;
          _previousFrameHeight = 0;
          _gridColumns = 0;
          _gridRows = 0;
        });
      }
      return;
    }

    _sampleTimer = Timer.periodic(widget.sampleInterval, (_) {
      _captureAndDiffFrame();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _captureAndDiffFrame();
      }
    });
  }

  Future<void> _captureAndDiffFrame() async {
    if (!mounted || !widget.isEnabled || _isCapturing) {
      return;
    }

    final BuildContext? context = _repaintBoundaryKey.currentContext;
    if (context == null) {
      return;
    }

    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary || !renderObject.hasSize) {
      return;
    }

    _isCapturing = true;
    try {
      final ui.Image image = await renderObject.toImage(pixelRatio: _capturePixelRatio);
      final int imageWidth = image.width;
      final int imageHeight = image.height;
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();

      if (byteData == null) {
        return;
      }

      _updateHeatMapFromBytes(
        byteData: byteData.buffer.asUint8List(),
        width: imageWidth,
        height: imageHeight,
      );
    } catch (_) {
      if (!_reportedUnavailable) {
        _reportedUnavailable = true;
        widget.onUnavailable?.call(
          'Animation highlight disabled: this renderer/device combination cannot safely sample frames.',
        );
      }
    } finally {
      _isCapturing = false;
    }
  }

  void _updateHeatMapFromBytes({
    required Uint8List byteData,
    required int width,
    required int height,
  }) {
    if (!mounted || width <= 0 || height <= 0) {
      return;
    }

    const int targetRows = 40;
    const int targetColumns = 24;
    final int cellWidth = (width / targetColumns).ceil().clamp(1, width);
    final int cellHeight = (height / targetRows).ceil().clamp(1, height);
    final int columns = (width / cellWidth).ceil();
    final int rows = (height / cellHeight).ceil();
    final int count = columns * rows;

    final Uint8List? previousFrameBytes = _previousFrameBytes;
    final bool hasComparablePreviousFrame =
        previousFrameBytes != null && _previousFrameWidth == width && _previousFrameHeight == height;

    if (!hasComparablePreviousFrame) {
      setState(() {
        _previousFrameBytes = Uint8List.fromList(byteData);
        _previousFrameWidth = width;
        _previousFrameHeight = height;
        _gridColumns = columns;
        _gridRows = rows;
        _heatByCell = <int, double>{};
      });
      return;
    }

    final List<int> changedCounts = List<int>.filled(count, 0);
    final List<int> sampleCounts = List<int>.filled(count, 0);
    const int sampleStride = 6;
    final double perPixelThreshold = widget.sensitivity;

    for (int y = 0; y < height; y += sampleStride) {
      final int row = (y / cellHeight).floor().clamp(0, rows - 1);
      for (int x = 0; x < width; x += sampleStride) {
        final int column = (x / cellWidth).floor().clamp(0, columns - 1);
        final int index = row * columns + column;
        final int pixelIndex = (y * width + x) * 4;
        if (pixelIndex + 2 >= byteData.length) {
          continue;
        }

        final double r = byteData[pixelIndex].toDouble();
        final double g = byteData[pixelIndex + 1].toDouble();
        final double b = byteData[pixelIndex + 2].toDouble();
        final double previousR = previousFrameBytes[pixelIndex].toDouble();
        final double previousG = previousFrameBytes[pixelIndex + 1].toDouble();
        final double previousB = previousFrameBytes[pixelIndex + 2].toDouble();
        final double averageChannelDelta = ((r - previousR).abs() + (g - previousG).abs() + (b - previousB).abs()) / 3;

        if (averageChannelDelta >= perPixelThreshold) {
          changedCounts[index]++;
        }
        sampleCounts[index]++;
      }
    }

    final DateTime now = DateTime.now();
    final DateTime? lastSampleAt = _lastSampleAt;
    _lastSampleAt = now;
    final double elapsedMs = lastSampleAt == null
        ? widget.sampleInterval.inMilliseconds.toDouble()
        : now.difference(lastSampleAt).inMilliseconds.toDouble();
    final double decayStep = elapsedMs / widget.decayDuration.inMilliseconds;

    bool shouldRepaint = false;
    final Map<int, double> nextHeat = <int, double>{};

    for (int i = 0; i < count; i++) {
      final int samples = sampleCounts[i];
      final double activity = samples == 0 ? 0.0 : changedCounts[i] / samples;
      final double activityHeat = (activity * 5.0).clamp(0.0, 1.0);
      final double previousHeat = _heatByCell[i] ?? 0;

      final double decayed = (previousHeat - decayStep).clamp(0.0, 1.0);
      final double nextValue = activityHeat > 0.02 ? (activityHeat > decayed ? activityHeat : decayed) : decayed;

      if (nextValue > 0.02) {
        nextHeat[i] = nextValue;
      }

      if ((nextValue - previousHeat).abs() > 0.01) {
        shouldRepaint = true;
      }
    }

    if (shouldRepaint ||
        _gridColumns != columns ||
        _gridRows != rows ||
        (_heatByCell.isEmpty && nextHeat.isNotEmpty) ||
        (_heatByCell.isNotEmpty && nextHeat.isEmpty)) {
      setState(() {
        _previousFrameBytes = Uint8List.fromList(byteData);
        _previousFrameWidth = width;
        _previousFrameHeight = height;
        _heatByCell = Map<int, double>.from(nextHeat);
        _gridColumns = columns;
        _gridRows = rows;
      });
      return;
    }

    _previousFrameBytes = Uint8List.fromList(byteData);
    _previousFrameWidth = width;
    _previousFrameHeight = height;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child: widget.child,
        ),
        if (widget.isEnabled)
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AnimationHeatmapPainter(
                  heatByCell: _heatByCell,
                  columns: _gridColumns,
                  rows: _gridRows,
                  opacity: widget.opacity,
                ),
                size: Size.infinite,
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimationHeatmapPainter extends CustomPainter {
  const _AnimationHeatmapPainter({
    required this.heatByCell,
    required this.columns,
    required this.rows,
    required this.opacity,
  });

  final Map<int, double> heatByCell;
  final int columns;
  final int rows;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns <= 0 || rows <= 0 || heatByCell.isEmpty) {
      return;
    }

    final double cellWidth = size.width / columns;
    final double cellHeight = size.height / rows;
    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final MapEntry<int, double> entry in heatByCell.entries) {
      final int index = entry.key;
      final double heat = entry.value.clamp(0.0, 1.0);
      if (heat <= 0.02) {
        continue;
      }

      final int row = index ~/ columns;
      final int column = index % columns;
      if (row >= rows) {
        continue;
      }

      final Rect rect = Rect.fromLTWH(
        column * cellWidth,
        row * cellHeight,
        cellWidth,
        cellHeight,
      );

      const Color start = Color(0xFFF7A250);
      const Color end = Color(0xFFE24A79);
      final Color color = Color.lerp(start, end, heat) ?? end;

      fillPaint.color = color.withValues(alpha: heat * opacity * 0.9);
      strokePaint.color = color.withValues(alpha: heat * opacity);

      final RRect rrect = RRect.fromRectAndRadius(
        rect.deflate(0.4),
        const Radius.circular(3),
      );

      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimationHeatmapPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.opacity != opacity ||
        oldDelegate.heatByCell != heatByCell;
  }
}
