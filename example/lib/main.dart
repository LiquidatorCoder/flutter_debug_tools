import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';
import 'package:loggy/loggy.dart';

void main() {
  // Add `DebugLoggyPrinter` to enable the debug logs
  Loggy.initLoggy(logPrinter: DebugLoggyPrinter());
  // Log messages
  logDebug('This is debug message');
  logInfo('This is info message');
  logWarning('This is warning message');
  logError('This is error message');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Add `DebugNavigatorObserver` to observe the screen details
    final DebugNavigatorObserver navigatorObserver = DebugNavigatorObserver();
    // Add `FlutterDebugTools` above your `MaterialApp` to enable the debug tools
    return FlutterDebugTools(builder: (context, shouldShowPerfOverlay, child) {
      return MaterialApp(
        showPerformanceOverlay: shouldShowPerfOverlay,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
        // Add `navigatorObservers` to observe the screen details
        navigatorObservers: [navigatorObserver],
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
