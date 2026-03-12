import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'captured_http_client.dart';
import 'demo_data.dart';
import 'demo_theme.dart';

class DemoAppController extends ChangeNotifier {
  DemoAppController({http.Client? client}) : _client = client ?? CapturedHttpClient() {
    _tasks = List<DemoTaskItem>.from(seedTasks);
  }

  final http.Client _client;

  bool showBanner = true;
  bool compactMetrics = false;
  bool notificationsEnabled = true;
  bool adaptiveGrid = true;
  bool isRefreshingOverview = false;
  bool isLoadingMoreTasks = false;
  bool isRefreshingTasks = false;
  bool showTaskSuccess = false;
  bool isNetworkBusy = false;
  bool isRefreshingNetwork = false;
  String selectedStatus = taskStatuses.first;
  String selectedSort = sortModes.first;
  String searchQuery = '';
  String networkHealth = 'Nominal';
  String networkActivityLabel = 'Idle';
  String? networkError;

  late List<DemoTaskItem> _tasks;
  final List<NetworkRun> _networkRuns = <NetworkRun>[];

  List<DemoTaskItem> get tasks => List<DemoTaskItem>.unmodifiable(_tasks);
  List<NetworkRun> get networkRuns => List<NetworkRun>.unmodifiable(_networkRuns.reversed);

  Future<void> initialize() async {
    await Future.wait(<Future<void>>[
      refreshOverview(),
      refreshNetworkDashboard(),
    ]);
  }

  Future<void> refreshOverview() async {
    isRefreshingOverview = true;
    notifyListeners();
    _log('debug', 'Refreshing overview metrics');
    await Future<void>.delayed(const Duration(milliseconds: 950));
    isRefreshingOverview = false;
    notifyListeners();
  }

  Future<void> refreshTasks() async {
    isRefreshingTasks = true;
    showTaskSuccess = false;
    notifyListeners();
    _log('info', 'Refreshing workspace queue');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _tasks = List<DemoTaskItem>.from(seedTasks);
    isRefreshingTasks = false;
    notifyListeners();
  }

  Future<void> loadMoreTasks() async {
    if (isLoadingMoreTasks) {
      return;
    }
    isLoadingMoreTasks = true;
    notifyListeners();
    _log('debug', 'Loading additional workspace rows');
    await Future<void>.delayed(const Duration(milliseconds: 850));
    final int offset = _tasks.length;
    _tasks = <DemoTaskItem>[
      ..._tasks,
      ...List<DemoTaskItem>.generate(4, (int index) {
        final int sequence = offset + index + 1;
        return DemoTaskItem(
          id: 'FL-${1200 + sequence}',
          title: 'Generated diagnostics sample $sequence',
          owner: workspaceTeams[sequence % workspaceTeams.length],
          status: taskStatuses[(sequence % (taskStatuses.length - 1)) + 1],
          priority: <String>['Low', 'Medium', 'High'][sequence % 3],
          summary: 'Extra row for pagination, search, and optimistic update checks.',
        );
      }),
    ];
    isLoadingMoreTasks = false;
    notifyListeners();
  }

  Future<void> submitTask({
    required String title,
    required String owner,
    required String priority,
    required bool notifyWatchers,
  }) async {
    _log('info', 'Submitting demo task "$title"');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _tasks = <DemoTaskItem>[
      DemoTaskItem(
        id: 'FL-${1300 + _tasks.length}',
        title: title,
        owner: owner,
        status: 'Ready',
        priority: priority,
        summary: notifyWatchers
            ? 'New task created with a watcher notification for log coverage.'
            : 'New task created without watcher notification.',
        pinned: true,
      ),
      ..._tasks,
    ];
    showTaskSuccess = true;
    notifyListeners();
  }

  Future<void> togglePinned(DemoTaskItem item) async {
    final int index = _tasks.indexWhere((DemoTaskItem task) => task.id == item.id);
    if (index < 0) {
      return;
    }
    final bool nextPinned = !_tasks[index].pinned;
    _tasks[index] = _tasks[index].copyWith(pinned: nextPinned);
    notifyListeners();
    _log('debug', '${nextPinned ? 'Pinned' : 'Unpinned'} ${item.id} optimistically');
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  Future<void> refreshNetworkDashboard() async {
    isRefreshingNetwork = true;
    networkError = null;
    notifyListeners();
    _log('info', 'Refreshing network lab overview');
    try {
      final http.Response response = await _client.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos/1'),
      );
      if (response.statusCode >= 400) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final Map<String, dynamic> payload = jsonDecode(response.body) as Map<String, dynamic>;
      networkHealth = payload['completed'] == true ? 'Nominal' : 'Watch';
    } catch (error) {
      networkHealth = 'Degraded';
      networkError = 'Unable to refresh overview: $error';
      _log('warn', networkError!);
    }
    isRefreshingNetwork = false;
    notifyListeners();
  }

  Future<void> runScenario(NetworkScenario scenario) async {
    if (isNetworkBusy) {
      return;
    }
    isNetworkBusy = true;
    networkActivityLabel = 'Running ${scenario.method} ${scenario.endpoint}';
    notifyListeners();

    _log('info', 'Running network scenario ${scenario.id}');

    try {
      switch (scenario.id) {
        case 'summary':
          await _requestSummary(scenario);
        case 'create':
          await _requestCreate(scenario);
        case 'patch':
          await _requestPatch(scenario);
        case 'delete':
          await _requestDelete(scenario);
        case 'not-found':
          await _request404(scenario);
        case 'retry':
          await _requestRetry(scenario);
        case 'parallel':
          await _requestParallel(scenario);
        case 'payload':
          await _requestPayload(scenario);
      }
    } catch (error) {
      _recordRun(
        scenario: scenario,
        statusLabel: 'Error',
        detail: '$error',
        tint: DemoTheme.error,
      );
      _log('error', 'Scenario ${scenario.id} failed: $error');
    } finally {
      isNetworkBusy = false;
      networkActivityLabel = 'Idle';
      notifyListeners();
    }
  }

  void dismissBanner() {
    showBanner = false;
    notifyListeners();
  }

  void toggleCompactMetrics(bool value) {
    compactMetrics = value;
    _log('debug', 'Compact metrics ${value ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    _log('info', 'Notifications ${value ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  void toggleAdaptiveGrid(bool value) {
    adaptiveGrid = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setStatus(String value) {
    selectedStatus = value;
    notifyListeners();
  }

  void setSort(String value) {
    selectedSort = value;
    notifyListeners();
  }

  List<DemoTaskItem> filteredTasks() {
    Iterable<DemoTaskItem> results = _tasks;
    if (selectedStatus != 'All') {
      results = results.where((DemoTaskItem item) => item.status == selectedStatus);
    }
    if (searchQuery.trim().isNotEmpty) {
      final String query = searchQuery.toLowerCase();
      results = results.where(
        (DemoTaskItem item) =>
            item.id.toLowerCase().contains(query) ||
            item.title.toLowerCase().contains(query) ||
            item.owner.toLowerCase().contains(query),
      );
    }

    final List<DemoTaskItem> sorted = results.toList();
    sorted.sort((DemoTaskItem a, DemoTaskItem b) {
      switch (selectedSort) {
        case 'Status':
          return a.status.compareTo(b.status);
        case 'Owner':
          return a.owner.compareTo(b.owner);
        case 'Priority':
        default:
          const Map<String, int> weight = <String, int>{'High': 0, 'Medium': 1, 'Low': 2};
          return (weight[a.priority] ?? 9).compareTo(weight[b.priority] ?? 9);
      }
    });
    return sorted;
  }

  void _recordRun({
    required NetworkScenario scenario,
    required String statusLabel,
    required String detail,
    required Color tint,
  }) {
    _networkRuns.add(
      NetworkRun(
        id: '${scenario.id}-${DateTime.now().microsecondsSinceEpoch}',
        title: scenario.title,
        method: scenario.method,
        endpoint: scenario.endpoint,
        startedAt: DateTime.now(),
        statusLabel: statusLabel,
        detail: detail,
        tint: tint,
      ),
    );
    if (_networkRuns.length > 24) {
      _networkRuns.removeAt(0);
    }
  }

  Future<void> _requestSummary(NetworkScenario scenario) async {
    final http.Response response = await _client.get(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
    );
    final Map<String, dynamic> payload = jsonDecode(response.body) as Map<String, dynamic>;
    _recordRun(
      scenario: scenario,
      statusLabel: 'HTTP ${response.statusCode}',
      detail: payload['title']?.toString() ?? 'summary loaded',
      tint: DemoTheme.success,
    );
  }

  Future<void> _requestCreate(NetworkScenario scenario) async {
    final http.Response response = await _client.post(
      Uri.parse('https://jsonplaceholder.typicode.com/posts'),
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{
        'title': 'flutterlens-demo',
        'body': 'Inspector payload sample',
        'userId': 7,
      }),
    );
    _recordRun(
      scenario: scenario,
      statusLabel: 'HTTP ${response.statusCode}',
      detail: 'Created mock record with body ${response.body.length} bytes',
      tint: DemoTheme.warning,
    );
  }

  Future<void> _requestPatch(NetworkScenario scenario) async {
    final http.Response response = await _client.patch(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{'title': 'patched title from FlutterLens demo'}),
    );
    _recordRun(
      scenario: scenario,
      statusLabel: 'HTTP ${response.statusCode}',
      detail: 'Partial update returned ${response.body.length} bytes',
      tint: DemoTheme.accent,
    );
  }

  Future<void> _requestDelete(NetworkScenario scenario) async {
    final http.Response response = await _client.delete(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
    );
    _recordRun(
      scenario: scenario,
      statusLabel: 'HTTP ${response.statusCode}',
      detail: 'Delete scenario completed successfully',
      tint: const Color(0xFF5A9BFF),
    );
  }

  Future<void> _request404(NetworkScenario scenario) async {
    final http.Response response = await _client.get(Uri.parse('https://httpstat.us/404'));
    _recordRun(
      scenario: scenario,
      statusLabel: 'HTTP ${response.statusCode}',
      detail: 'Intentional not-found response for recovery testing',
      tint: DemoTheme.error,
    );
  }

  Future<void> _requestRetry(NetworkScenario scenario) async {
    int attempts = 0;
    http.Response? response;
    for (int index = 0; index < 3; index++) {
      attempts = index + 1;
      response = await _client.get(Uri.parse('https://httpstat.us/503?sleep=180'));
      if (response.statusCode < 500) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 240));
    }
    _recordRun(
      scenario: scenario,
      statusLabel: 'HTTP ${response?.statusCode ?? 503}',
      detail: 'Completed after $attempts attempts',
      tint: DemoTheme.warning,
    );
  }

  Future<void> _requestParallel(NetworkScenario scenario) async {
    final List<http.Response> responses = await Future.wait(<Future<http.Response>>[
      _client.get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1')),
      _client.get(Uri.parse('https://jsonplaceholder.typicode.com/comments/1')),
      _client.get(Uri.parse('https://httpstat.us/418')),
    ]);
    final String joined = responses.map((http.Response response) => response.statusCode.toString()).join(', ');
    _recordRun(
      scenario: scenario,
      statusLabel: 'Burst',
      detail: 'Statuses: $joined',
      tint: const Color(0xFF9A7BFF),
    );
  }

  Future<void> _requestPayload(NetworkScenario scenario) async {
    final http.Response response = await _client.get(
      Uri.parse('https://jsonplaceholder.typicode.com/comments'),
    );
    _recordRun(
      scenario: scenario,
      statusLabel: 'HTTP ${response.statusCode}',
      detail: 'Downloaded ${response.bodyBytes.length} bytes',
      tint: const Color(0xFF00B8D9),
    );
  }

  void _log(String level, String message) {
    debugPrint('$level: $message');
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
