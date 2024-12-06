import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';

class RenderBoxInspector extends StatefulWidget {
  final Widget child;
  const RenderBoxInspector({super.key, required this.child});

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
    final top = (_selectedRenderBox?.targetRectShifted.top ?? 0) -
        (_selectedRenderBox?.paddingTop ?? 0) +
        (_selectedRenderBox?.targetRect.height ?? 0) +
        (_selectedRenderBox?.paddingVertical ?? 0);
    final isBottomCropping = top + 71 > MediaQuery.of(context).size.height;

    final left = (_selectedRenderBox?.targetRectShifted.left ?? 0);
    final isRightCropping = left + 20 > MediaQuery.of(context).size.width / 2;
    final maxWidth = isRightCropping ? left : (MediaQuery.of(context).size.width - left);

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
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: 1,
                  ),
                  color: Colors.blue.withOpacity(0.1),
                ),
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
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.yellow,
                    width: 1,
                  ),
                  color: Colors.yellow.withOpacity(0.3),
                ),
                width: _selectedRenderBox?.targetRect.width,
                height: _selectedRenderBox?.targetRect.height,
              ),
            ),
          ),
        if (show)
          Positioned(
            left: isRightCropping ? null : left,
            right: isRightCropping
                ? MediaQuery.of(context).size.width - left - (_selectedRenderBox?.targetRect.width ?? 0)
                : null,
            top: !isBottomCropping ? top : (_selectedRenderBox?.targetRectShifted.top ?? 0) - 70,
            child: IgnorePointer(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                height: 70,
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "padding: ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: (_selectedRenderBox?.paddingRect)
                                .toString()
                                .replaceAll("Rect.fromLTRB(", "")
                                .replaceAll(")", ""),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "size: ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text:
                                "${_selectedRenderBox?.targetRect.width.roundToDouble()}, ${_selectedRenderBox?.targetRect.height.roundToDouble()}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
