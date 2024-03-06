import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class PixelColorInspector extends StatefulWidget {
  final void Function(Color) onColorPicked;
  final Widget child;
  const PixelColorInspector({Key? key, required this.child, required this.onColorPicked}) : super(key: key);

  @override
  State<PixelColorInspector> createState() => _PixelColorInspectorState();
}

class _PixelColorInspectorState extends State<PixelColorInspector> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  ui.Image? _image;
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureImage());
  }

  Future<void> _captureImage() async {
    RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    _image = await boundary.toImage(pixelRatio: pixelRatio);
    setState(() {});
  }

  Color? getPixelFromByteData(
    ByteData byteData, {
    required int width,
    required int x,
    required int y,
  }) {
    final index = (y * width + x) * 4;

    if (index + 3 < byteData.lengthInBytes) {
      // Ensure we're not reading past the end of the ByteData buffer
      final r = byteData.getUint8(index);
      final g = byteData.getUint8(index + 1);
      final b = byteData.getUint8(index + 2);
      final a = byteData.getUint8(index + 3);

      return Color.fromARGB(a, r, g, b);
    } else {
      // Handle the error or ignore
      debugPrint("Error: Attempted to read outside the ByteData buffer.");
      return null;
    }
  }

  Future<void> _showPixelColor(Offset globalPosition) async {
    if (_image == null) return;

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    var offset = (_repaintBoundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary)
        .globalToLocal(globalPosition);

    offset *= pixelRatio;

    final int pixelX = offset.dx.round();
    final int pixelY = offset.dy.round();

    if (pixelX < 0 || pixelY < 0 || pixelX >= _image!.width || pixelY >= _image!.height) {
      // Coordinates are outside the bounds of the image
      return;
    }

    final ByteData? byteData = await _image!.toByteData(format: ui.ImageByteFormat.rawRgba);

    setState(() {
      if (byteData != null) {
        _selectedColor = getPixelFromByteData(byteData, width: _image?.width ?? 0, x: pixelX, y: pixelY);
      }
    });

    final color = _selectedColor;
    if (color != null) {
      widget.onColorPicked(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (e) => _showPixelColor(e.position),
      child: IgnorePointer(
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: widget.child,
        ),
      ),
    );
  }
}
