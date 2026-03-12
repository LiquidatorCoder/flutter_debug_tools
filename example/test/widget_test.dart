import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/src/demo_theme.dart';
import 'package:example/src/demo_widgets.dart';

void main() {
  testWidgets('demo surface renders content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DemoTheme.theme(),
        home: const Scaffold(
          body: DemoSurface(
            child: Text('FlutterLens'),
          ),
        ),
      ),
    );

    expect(find.text('FlutterLens'), findsOneWidget);
    expect(find.byType(DemoSurface), findsOneWidget);
  });
}
