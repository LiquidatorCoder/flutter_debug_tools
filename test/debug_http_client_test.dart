import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debug_tools/src/network_capture/debug_network_capture_io.dart';

void main() {
  group('_DebugHttpClient property forwarding', () {
    late HttpClient wrappedClient;

    setUp(() {
      installDebugNetworkCapture();
      wrappedClient = HttpClient();
    });

    tearDown(() {
      wrappedClient.close(force: true);
    });

    test('idleTimeout getter and setter are forwarded', () {
      const Duration timeout = Duration(seconds: 42);
      wrappedClient.idleTimeout = timeout;
      expect(wrappedClient.idleTimeout, equals(timeout));
    });

    test('connectionTimeout getter and setter are forwarded', () {
      const Duration timeout = Duration(seconds: 10);
      wrappedClient.connectionTimeout = timeout;
      expect(wrappedClient.connectionTimeout, equals(timeout));
    });

    test('connectionTimeout can be set to null', () {
      wrappedClient.connectionTimeout = null;
      expect(wrappedClient.connectionTimeout, isNull);
    });

    test('maxConnectionsPerHost getter and setter are forwarded', () {
      wrappedClient.maxConnectionsPerHost = 5;
      expect(wrappedClient.maxConnectionsPerHost, equals(5));
    });

    test('maxConnectionsPerHost can be set to null', () {
      wrappedClient.maxConnectionsPerHost = null;
      expect(wrappedClient.maxConnectionsPerHost, isNull);
    });

    test('userAgent getter and setter are forwarded', () {
      const String agent = 'TestAgent/1.0';
      wrappedClient.userAgent = agent;
      expect(wrappedClient.userAgent, equals(agent));
    });

    test('userAgent can be set to null', () {
      wrappedClient.userAgent = null;
      expect(wrappedClient.userAgent, isNull);
    });

    test('autoUncompress getter and setter are forwarded', () {
      wrappedClient.autoUncompress = false;
      expect(wrappedClient.autoUncompress, isFalse);
      wrappedClient.autoUncompress = true;
      expect(wrappedClient.autoUncompress, isTrue);
    });
  });
}
