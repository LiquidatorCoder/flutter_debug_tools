import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';

import 'src/demo_app.dart';

Future<void> main() async {
  await DebugLogCapture.runApp(() async {
    debugPrint('info: FlutterLens example flow booting');
    runApp(const DemoApp());
  });
}
