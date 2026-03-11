import 'package:flutter/material.dart';

const String flutterLensFontFamily = 'packages/flutter_debug_tools/DMSans';

ThemeData flutterLensTheme(BuildContext context) {
  final baseTheme = Theme.of(context);
  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: flutterLensFontFamily),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: flutterLensFontFamily),
  );
}
