import 'package:flutter/material.dart';

class DemoModule {
  const DemoModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.surface,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String surface;
}

class DemoTaskItem {
  const DemoTaskItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.status,
    required this.priority,
    required this.summary,
    this.pinned = false,
  });

  final String id;
  final String title;
  final String owner;
  final String status;
  final String priority;
  final String summary;
  final bool pinned;

  DemoTaskItem copyWith({bool? pinned}) {
    return DemoTaskItem(
      id: id,
      title: title,
      owner: owner,
      status: status,
      priority: priority,
      summary: summary,
      pinned: pinned ?? this.pinned,
    );
  }
}

class NetworkScenario {
  const NetworkScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.method,
    required this.endpoint,
    required this.tint,
  });

  final String id;
  final String title;
  final String description;
  final String method;
  final String endpoint;
  final Color tint;
}

class NetworkRun {
  const NetworkRun({
    required this.id,
    required this.title,
    required this.method,
    required this.endpoint,
    required this.startedAt,
    required this.statusLabel,
    required this.detail,
    required this.tint,
  });

  final String id;
  final String title;
  final String method;
  final String endpoint;
  final DateTime startedAt;
  final String statusLabel;
  final String detail;
  final Color tint;
}

const List<DemoModule> demoModules = <DemoModule>[
  DemoModule(
    title: 'Debug Paint',
    subtitle: 'Dense composition and spacing audit',
    icon: Icons.grid_view_rounded,
    surface: 'Dashboard composition blocks and adaptive cards',
  ),
  DemoModule(
    title: 'Size Info',
    subtitle: 'Flexible and constrained panels',
    icon: Icons.straighten_rounded,
    surface: 'Responsive metrics, forms, and split layouts',
  ),
  DemoModule(
    title: 'Repaint Rainbow',
    subtitle: 'Animated list, charts, and moving badges',
    icon: Icons.auto_awesome_rounded,
    surface: 'Motion Lab orbit, ticker row, and stream cards',
  ),
  DemoModule(
    title: 'Debug Logs',
    subtitle: 'Action-heavy flows emit structured logs',
    icon: Icons.notes_rounded,
    surface: 'Submit forms, run requests, open dialogs, navigate routes',
  ),
  DemoModule(
    title: 'Perf Overlay',
    subtitle: 'Scroll stress, painters, and animations',
    icon: Icons.monitor_heart_rounded,
    surface: 'Long lists, animated charts, gallery cards, and custom paint',
  ),
  DemoModule(
    title: 'Color Picker',
    subtitle: 'Semantic colors, gradients, and tinted chips',
    icon: Icons.palette_outlined,
    surface: 'Status pills, hero gradients, chart legends, and settings swatches',
  ),
  DemoModule(
    title: 'Device Details',
    subtitle: 'Context-rich environment surface',
    icon: Icons.devices_rounded,
    surface: 'Settings and device snapshot page',
  ),
  DemoModule(
    title: 'Screen Name',
    subtitle: 'Explicit routes with nested stacks',
    icon: Icons.route_rounded,
    surface: 'Tab navigators, detail routes, sheets, and full-screen command center',
  ),
  DemoModule(
    title: 'Animation Toolbox',
    subtitle: 'Curves, stagger, implicit, and explicit motion',
    icon: Icons.animation_rounded,
    surface: 'Motion Lab with opt-in curve scope previews',
  ),
  DemoModule(
    title: 'Network Inspector',
    subtitle: 'Requests, retries, payloads, and failures',
    icon: Icons.wifi_tethering_rounded,
    surface: 'Network Lab request dashboard and retry flows',
  ),
];

const List<DemoTaskItem> seedTasks = <DemoTaskItem>[
  DemoTaskItem(
    id: 'FL-1082',
    title: 'Align tablet card gutters',
    owner: 'Maya Chen',
    status: 'Ready',
    priority: 'High',
    summary: 'Verifies responsive spacing and width constraints across adaptive panes.',
    pinned: true,
  ),
  DemoTaskItem(
    id: 'FL-1091',
    title: 'Capture retry telemetry',
    owner: 'Jon Park',
    status: 'Blocked',
    priority: 'High',
    summary: 'Exercises log capture and network retries through a simulated outage.',
  ),
  DemoTaskItem(
    id: 'FL-1107',
    title: 'Tune motion stack previews',
    owner: 'Noor Singh',
    status: 'Review',
    priority: 'Medium',
    summary: 'Provides explicit animation surfaces for speed, curve, and frame tooling.',
  ),
  DemoTaskItem(
    id: 'FL-1123',
    title: 'Stress long-scroll activity feed',
    owner: 'Ada Brooks',
    status: 'Ready',
    priority: 'Low',
    summary: 'Useful for perf overlays, repaint inspection, and pagination validation.',
  ),
  DemoTaskItem(
    id: 'FL-1144',
    title: 'Validate semantic palettes',
    owner: 'Eli Gomez',
    status: 'Live',
    priority: 'Medium',
    summary: 'Introduces rich semantic color usage for color inspection and contrast review.',
  ),
];

const List<String> workspaceTeams = <String>['Platform', 'Mobile', 'QA', 'Infra'];
const List<String> taskStatuses = <String>['All', 'Ready', 'Review', 'Blocked', 'Live'];
const List<String> sortModes = <String>['Priority', 'Status', 'Owner'];

const List<NetworkScenario> networkScenarios = <NetworkScenario>[
  NetworkScenario(
    id: 'summary',
    title: 'GET summary payload',
    description: 'Happy-path request with compact JSON payload.',
    method: 'GET',
    endpoint: 'https://jsonplaceholder.typicode.com/posts/1',
    tint: Color(0xFF4ADE80),
  ),
  NetworkScenario(
    id: 'create',
    title: 'POST create event',
    description: 'Sends a structured body for inspector payload review.',
    method: 'POST',
    endpoint: 'https://jsonplaceholder.typicode.com/posts',
    tint: Color(0xFFF7A250),
  ),
  NetworkScenario(
    id: 'patch',
    title: 'PATCH partial update',
    description: 'Small mutation request with headers and body.',
    method: 'PATCH',
    endpoint: 'https://jsonplaceholder.typicode.com/posts/1',
    tint: Color(0xFFE24A79),
  ),
  NetworkScenario(
    id: 'delete',
    title: 'DELETE archive item',
    description: 'Endpoint with a short, successful empty response.',
    method: 'DELETE',
    endpoint: 'https://jsonplaceholder.typicode.com/posts/1',
    tint: Color(0xFF5A9BFF),
  ),
  NetworkScenario(
    id: 'not-found',
    title: 'GET 404 response',
    description: 'Intentional failure path for empty and retry states.',
    method: 'GET',
    endpoint: 'https://httpstat.us/404',
    tint: Color(0xFFFF6B7A),
  ),
  NetworkScenario(
    id: 'retry',
    title: 'Retry 503 burst',
    description: 'Three attempts with backoff to test retries and errors.',
    method: 'GET',
    endpoint: 'https://httpstat.us/503?sleep=180',
    tint: Color(0xFFFF8B3D),
  ),
  NetworkScenario(
    id: 'parallel',
    title: 'Parallel burst',
    description: 'Multiple calls at once for inspector list density.',
    method: 'GET',
    endpoint: '3 parallel endpoints',
    tint: Color(0xFF9A7BFF),
  ),
  NetworkScenario(
    id: 'payload',
    title: 'Large payload',
    description: 'Downloads a wider body to inspect timing and size.',
    method: 'GET',
    endpoint: 'https://jsonplaceholder.typicode.com/comments',
    tint: Color(0xFF00B8D9),
  ),
];
