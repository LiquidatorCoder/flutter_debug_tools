import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';

Future<void> main() async {
  await DebugLogCapture.runApp(() async {
    debugPrint('debug: This is debug message');
    debugPrint('info: This is info message');
    debugPrint('warn: This is warning message');
    debugPrint('error: This is error message');
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Add `DebugNavigatorObserver` to observe the screen details
    final DebugNavigatorObserver navigatorObserver = DebugNavigatorObserver();
    // Add `FlutterLens` above your `MaterialApp` to enable FlutterLens
    return FlutterLens(
      builder: (context, shouldShowPerfOverlay, child) {
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
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _counter = 0;
  bool _animateCard = false;
  bool _toggleExtras = false;
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      _animateCard = !_animateCard;
      _toggleExtras = !_toggleExtras;
    });
  }

  @override
  Widget build(BuildContext context) {
    final switchCurve = FlutterLensAnimationCurveScope.resolve(context, Curves.easeOutBack);
    final cardCurve = FlutterLensAnimationCurveScope.resolve(context, Curves.easeInOutCubic);
    final pulseCurve = FlutterLensAnimationCurveScope.resolve(context, Curves.easeInOut);

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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: switchCurve,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                '$_counter',
                key: ValueKey<int>(_counter),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 28),
            RotationTransition(
              turns: _rotationController,
              child: Icon(
                Icons.settings_suggest_rounded,
                size: 38,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              curve: cardCurve,
              width: _animateCard ? 220 : 160,
              height: _animateCard ? 72 : 56,
              decoration: BoxDecoration(
                color: _animateCard
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(_animateCard ? 22 : 14),
              ),
              alignment: Alignment.center,
              child: const Text('Animation demo'),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: Tween<double>(begin: 0.25, end: 1.0).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: pulseCurve,
                ),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: pulseCurve,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Pulse + fade'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              height: 44,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 550),
                curve: cardCurve,
                alignment: _toggleExtras ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 104,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Slide'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 480),
              curve: pulseCurve,
              opacity: _toggleExtras ? 1.0 : 0.2,
              child: Container(
                width: 140,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
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
