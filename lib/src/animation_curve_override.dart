import 'package:flutter/material.dart';

class FlutterLensAnimationCurveScope extends InheritedWidget {
  const FlutterLensAnimationCurveScope({
    super.key,
    required super.child,
    this.overrideCurve,
  });

  final Curve? overrideCurve;

  static Curve resolve(BuildContext context, Curve fallback) {
    final scope = context.dependOnInheritedWidgetOfExactType<FlutterLensAnimationCurveScope>();
    return scope?.overrideCurve ?? fallback;
  }

  @override
  bool updateShouldNotify(covariant FlutterLensAnimationCurveScope oldWidget) {
    return oldWidget.overrideCurve != overrideCurve;
  }
}
