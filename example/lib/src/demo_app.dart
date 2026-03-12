import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';

import 'demo_controller.dart';
import 'demo_shell.dart';
import 'demo_theme.dart';

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final DemoAppController _controller;
  late final DebugNavigatorObserver _navigatorObserver;

  @override
  void initState() {
    super.initState();
    _controller = DemoAppController();
    _navigatorObserver = DebugNavigatorObserver();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLens(
      builder: (BuildContext context, bool shouldShowPerfOverlay, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FlutterLens Example Flow',
          showPerformanceOverlay: shouldShowPerfOverlay,
          navigatorObservers: <NavigatorObserver>[_navigatorObserver],
          theme: DemoTheme.theme(),
          home: DemoShell(controller: _controller),
        );
      },
    );
  }
}
