import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';
import 'package:http/http.dart' as http;

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
  bool _isCallingNetwork = false;
  String _networkStatus = 'No request yet';
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

  Future<void> _runGetExample() {
    return _runNetworkAction(
      label: 'GET /posts/1',
      action: () async {
        final Uri uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');
        final http.Response response = await http.get(uri);
        if (response.statusCode >= 400) {
          throw Exception('HTTP ${response.statusCode}');
        }
        final dynamic payload = jsonDecode(response.body);
        final String title =
            payload is Map<String, dynamic> ? (payload['title']?.toString() ?? 'no title') : 'no title';
        return 'OK ${response.statusCode} | $title';
      },
    );
  }

  Future<void> _runPostExample() {
    return _runNetworkAction(
      label: 'POST /posts',
      action: () async {
        final Uri uri = Uri.parse('https://jsonplaceholder.typicode.com/posts');
        final http.Response response = await http.post(
          uri,
          headers: const <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'X-Demo-Flow': 'flutter-lens-network',
          },
          body: jsonEncode(<String, dynamic>{
            'title': 'FlutterLens demo',
            'body': 'Network inspector sample payload',
            'userId': 7,
          }),
        );
        if (response.statusCode >= 400) {
          throw Exception('HTTP ${response.statusCode}');
        }
        return 'OK ${response.statusCode} | created id present';
      },
    );
  }

  Future<void> _runFailureWithRetriesExample() {
    return _runNetworkAction(
      label: 'Retry demo (forced failure)',
      action: () async {
        const int maxAttempts = 3;
        final Uri uri = Uri.parse('https://httpstat.us/503?sleep=300');

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
          final http.Response response = await http.get(uri);
          if (response.statusCode < 400) {
            return 'Recovered on attempt $attempt';
          }
          if (attempt < maxAttempts) {
            await Future<void>.delayed(const Duration(milliseconds: 280));
          }
        }

        throw Exception('Failed after $maxAttempts attempts (expected for demo)');
      },
    );
  }

  Future<void> _runPatchExample() {
    return _runNetworkAction(
      label: 'PATCH /posts/1',
      action: () async {
        final Uri uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');
        final http.Response response = await http.patch(
          uri,
          headers: const <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'X-Demo-Action': 'partial-update',
          },
          body: jsonEncode(<String, dynamic>{
            'title': 'patched title from FlutterLens demo',
          }),
        );
        if (response.statusCode >= 400) {
          throw Exception('HTTP ${response.statusCode}');
        }
        return 'OK ${response.statusCode} | partial update';
      },
    );
  }

  Future<void> _runDeleteExample() {
    return _runNetworkAction(
      label: 'DELETE /posts/1',
      action: () async {
        final Uri uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');
        final http.Response response = await http.delete(
          uri,
          headers: const <String, String>{
            'X-Demo-Action': 'delete',
          },
        );
        if (response.statusCode >= 400) {
          throw Exception('HTTP ${response.statusCode}');
        }
        return 'OK ${response.statusCode} | delete mock';
      },
    );
  }

  Future<void> _runNotFoundExample() {
    return _runNetworkAction(
      label: 'GET forced 404',
      action: () async {
        final Uri uri = Uri.parse('https://httpstat.us/404');
        final http.Response response = await http.get(uri);
        return 'HTTP ${response.statusCode} | expected not found';
      },
    );
  }

  Future<void> _runBurstExample() {
    return _runNetworkAction(
      label: 'Burst demo (parallel)',
      action: () async {
        final List<Future<http.Response>> calls = <Future<http.Response>>[
          http.get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1')),
          http.get(Uri.parse('https://jsonplaceholder.typicode.com/comments/1')),
          http.get(Uri.parse('https://httpstat.us/418')),
        ];
        final List<http.Response> results = await Future.wait(calls);
        final String statuses = results.map((response) => response.statusCode.toString()).join(', ');
        return 'Done | statuses: $statuses';
      },
    );
  }

  Future<void> _runBigPayloadExample() {
    return _runNetworkAction(
      label: 'Big payload demo',
      action: () async {
        final Uri uri = Uri.parse('https://jsonplaceholder.typicode.com/comments');
        final http.Response response = await http.get(uri);
        if (response.statusCode >= 400) {
          throw Exception('HTTP ${response.statusCode}');
        }
        return 'OK ${response.statusCode} | bytes: ${response.bodyBytes.length}';
      },
    );
  }

  Future<void> _runNetworkAction({
    required String label,
    required Future<String> Function() action,
  }) async {
    if (_isCallingNetwork) {
      return;
    }

    setState(() {
      _isCallingNetwork = true;
      _networkStatus = '$label: running...';
    });

    try {
      final String result = await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _networkStatus = '$label: $result';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _networkStatus = '$label: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCallingNetwork = false;
        });
      }
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
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
              const SizedBox(height: 20),
              const Text(
                'Network inspector demo calls',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isCallingNetwork ? null : _runGetExample,
                    child: const Text('GET success'),
                  ),
                  ElevatedButton(
                    onPressed: _isCallingNetwork ? null : _runPostExample,
                    child: const Text('POST payload'),
                  ),
                  ElevatedButton(
                    onPressed: _isCallingNetwork ? null : _runPatchExample,
                    child: const Text('PATCH update'),
                  ),
                  ElevatedButton(
                    onPressed: _isCallingNetwork ? null : _runDeleteExample,
                    child: const Text('DELETE call'),
                  ),
                  OutlinedButton(
                    onPressed: _isCallingNetwork ? null : _runNotFoundExample,
                    child: const Text('GET 404'),
                  ),
                  OutlinedButton(
                    onPressed: _isCallingNetwork ? null : _runFailureWithRetriesExample,
                    child: const Text('Retry failure'),
                  ),
                  OutlinedButton(
                    onPressed: _isCallingNetwork ? null : _runBurstExample,
                    child: const Text('Parallel burst'),
                  ),
                  OutlinedButton(
                    onPressed: _isCallingNetwork ? null : _runBigPayloadExample,
                    child: const Text('Big payload'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 320,
                child: Text(
                  _networkStatus,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
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
