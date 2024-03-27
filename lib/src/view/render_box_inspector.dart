import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';

class RenderBoxInspector extends StatefulWidget {
  final Widget child;
  const RenderBoxInspector({Key? key, required this.child}) : super(key: key);

  @override
  State<RenderBoxInspector> createState() => _RenderBoxInspectorState();
}

class _RenderBoxInspectorState extends State<RenderBoxInspector> {
  final GlobalKey _absorbPointerKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();

  RenderBoxInfo? _selectedRenderBox;

  get show => _selectedRenderBox != null;

  RenderBox? _bypassAbsorbPointer(RenderProxyBox renderObject) {
    RenderBox lastObject = renderObject;

    while (lastObject is! RenderAbsorbPointer) {
      lastObject = renderObject.child!;
    }

    return lastObject.child;
  }

  Iterable<RenderBox> _getBoxes(BuildContext context, Offset? pointerOffset) {
    final renderObject = context.findRenderObject() as RenderProxyBox?;

    if (renderObject == null) return [];

    final renderObjectWithoutAbsorbPointer = _bypassAbsorbPointer(renderObject);

    if (renderObjectWithoutAbsorbPointer == null) return [];

    final hitTestResult = BoxHitTestResult();
    if (pointerOffset == null) return [];
    renderObjectWithoutAbsorbPointer.hitTest(
      hitTestResult,
      position: renderObjectWithoutAbsorbPointer.globalToLocal(pointerOffset),
    );

    return hitTestResult.path.where((v) => v.target is RenderBox).map((v) => v.target).cast<RenderBox>();
  }

  void _getRenderBox(Offset? offset) {
    final context = _absorbPointerKey.currentContext;
    if (context == null) return;

    final boxes = _getBoxes(context, offset);
    if (boxes.isEmpty) return;

    final overlayOffset = (_stackKey.currentContext?.findRenderObject() as RenderStack).localToGlobal(Offset.zero);

    RenderBox? targetRenderBox;
    RenderBox? containerRenderBox;

    for (final box in boxes) {
      targetRenderBox ??= box;

      if (targetRenderBox.size < box.size) {
        containerRenderBox = box;
        break;
      }
    }

    setState(() {
      _selectedRenderBox = RenderBoxInfo(
        targetRenderBox: targetRenderBox!,
        containerRenderBox: containerRenderBox,
        overlayOffset: overlayOffset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerUp: (e) => _getRenderBox(e.position),
          child: AbsorbPointer(
            key: _absorbPointerKey,
            absorbing: true,
            child: widget.child,
          ),
        ),
        if (show)
          Positioned(
            left: (_selectedRenderBox?.targetRectShifted.left ?? 0) - (_selectedRenderBox?.paddingLeft ?? 0),
            top: (_selectedRenderBox?.targetRectShifted.top ?? 0) - (_selectedRenderBox?.paddingTop ?? 0),
            child: IgnorePointer(
              child: Container(
                color: Colors.blue.withOpacity(0.1),
                width: (_selectedRenderBox?.targetRect.width ?? 0) + (_selectedRenderBox?.paddingHorizontal ?? 0),
                height: (_selectedRenderBox?.targetRect.height ?? 0) + (_selectedRenderBox?.paddingVertical ?? 0),
              ),
            ),
          ),
        if (show)
          Positioned(
            left: _selectedRenderBox?.targetRectShifted.left,
            top: _selectedRenderBox?.targetRectShifted.top,
            child: IgnorePointer(
              child: Container(
                color: Colors.yellow.withOpacity(0.3),
                width: _selectedRenderBox?.targetRect.width,
                height: _selectedRenderBox?.targetRect.height,
              ),
            ),
          ),
      ],
    );
  }
}
