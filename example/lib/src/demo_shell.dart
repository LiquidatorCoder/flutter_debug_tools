import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';

import 'demo_controller.dart';
import 'demo_data.dart';
import 'demo_theme.dart';
import 'demo_widgets.dart';

enum _DemoTab { overview, workspace, network, motion, settings }

class DemoShell extends StatefulWidget {
  const DemoShell({super.key, required this.controller});

  final DemoAppController controller;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
      _DemoTab.values.length,
      (_) => GlobalKey<NavigatorState>(),
    );
  }

  Future<bool> _handleWillPop() async {
    final NavigatorState currentNavigator = _navigatorKeys[_currentIndex].currentState!;
    if (currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    return true;
  }

  void _selectTab(int index) {
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((Route<dynamic> route) => route.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
    debugPrint('info: Switched to ${_DemoTab.values[index].name} tab');
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        final bool shouldPop = await _handleWillPop();
        if (shouldPop && mounted) {
          navigator.maybePop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: _DemoDrawer(controller: widget.controller),
        body: Stack(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF0A0C0F), DemoTheme.canvas, Color(0xFF090B0E)],
                ),
              ),
              child: IndexedStack(
                index: _currentIndex,
                children: _DemoTab.values.indexed.map((entry) {
                  return Offstage(
                    offstage: _currentIndex != entry.$1,
                    child: _TabNavigator(
                      navigatorKey: _navigatorKeys[entry.$1],
                      tab: entry.$2,
                      controller: widget.controller,
                      onMenuTap: _openDrawer,
                    ),
                  );
                }).toList(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _DemoBottomBar(
                currentIndex: _currentIndex,
                onTap: _selectTab,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.tab,
    required this.controller,
    required this.onMenuTap,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final _DemoTab tab;
  final DemoAppController controller;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        Widget page;
        bool fullscreenDialog = false;
        switch (tab) {
          case _DemoTab.overview:
            page = _buildOverviewRoute(settings);
          case _DemoTab.workspace:
            page = _buildWorkspaceRoute(settings);
          case _DemoTab.network:
            page = NetworkLabScreen(controller: controller, onMenuTap: onMenuTap);
          case _DemoTab.motion:
            page = MotionLabScreen(onMenuTap: onMenuTap);
          case _DemoTab.settings:
            page = SettingsScreen(controller: controller, onMenuTap: onMenuTap);
        }
        if (settings.name == '/command-center') {
          fullscreenDialog = true;
        }
        return MaterialPageRoute<void>(
          builder: (_) => page,
          settings: settings,
          fullscreenDialog: fullscreenDialog,
        );
      },
      observers: <NavigatorObserver>[DebugNavigatorObserver()],
    );
  }

  Widget _buildOverviewRoute(RouteSettings settings) {
    if (settings.name == '/module-detail') {
      return ModuleDetailScreen(module: settings.arguments! as DemoModule);
    }
    if (settings.name == '/command-center') {
      return const CommandCenterScreen();
    }
    return OverviewScreen(controller: controller, onMenuTap: onMenuTap);
  }

  Widget _buildWorkspaceRoute(RouteSettings settings) {
    if (settings.name == '/task-detail') {
      return TaskDetailScreen(task: settings.arguments! as DemoTaskItem);
    }
    return WorkspaceScreen(controller: controller, onMenuTap: onMenuTap);
  }
}

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.controller, required this.onMenuTap});

  final DemoAppController controller;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return RefreshIndicator(
          onRefresh: controller.refreshOverview,
          color: DemoTheme.accent,
          child: DemoPage(
            title: 'Example Flow',
            subtitle: 'A polished diagnostic playground aligned to the FlutterLens tools flow.',
            onMenuTap: onMenuTap,
            trailing: DemoPill(
              label: controller.isRefreshingOverview ? 'Refreshing' : 'Live Surface',
              color: controller.isRefreshingOverview ? DemoTheme.warning : DemoTheme.success,
              active: true,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (controller.showBanner) ...<Widget>[
                  DemoBanner(
                    title: 'Diagnostic coverage ready',
                    message: 'Every primary tool has a clear surface here: routes, motion, logs, state, and network.',
                    onDismiss: controller.dismissBanner,
                  ),
                  const SizedBox(height: 20),
                ],
                _OverviewHero(controller: controller),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool split = constraints.maxWidth > 820;
                    final Widget modules = _ModulesPanel();
                    final Widget activity = _ActivityPanel(controller: controller);
                    if (split) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 6, child: modules),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: activity),
                        ],
                      );
                    }
                    return Column(
                      children: <Widget>[modules, const SizedBox(height: 16), activity],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _DiagnosticLayoutShowcase(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({required this.controller});

  final DemoAppController controller;

  @override
  Widget build(BuildContext context) {
    final List<Widget> metricTiles = <Widget>[
      DemoMetricTile(
          label: 'Routes', value: '12', caption: 'Nested tabs, detail screens, overlays', tint: DemoTheme.success),
      DemoMetricTile(
          label: 'States', value: '9', caption: 'Loading, empty, error, success, retry', tint: DemoTheme.warning),
      DemoMetricTile(
          label: 'Actions',
          value: '48',
          caption: 'Logs emitted across forms, requests, and nav',
          tint: DemoTheme.accent),
      DemoMetricTile(
          label: 'Surfaces',
          value: '10',
          caption: 'Intentional coverage for each FlutterLens tool',
          tint: DemoTheme.success),
    ];

    return DemoSurface(
      padding: const EdgeInsets.all(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.fromRGBO(247, 162, 80, 0.18),
          Color.fromRGBO(22, 22, 25, 0.96),
          Color.fromRGBO(90, 51, 134, 0.24),
        ],
      ),
      borderColor: DemoTheme.borderStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Technical, precise, and route-rich by design.',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      'Use this flow to validate overlays, constrained layout inspection, repaints, logs, networking, device metadata, and animation controls in a realistic product shell.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: controller.compactMetrics,
                onChanged: controller.toggleCompactMetrics,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/module-detail', arguments: demoModules.first),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open detail route'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showQuickSheet(context),
                icon: const Icon(Icons.splitscreen_rounded),
                label: const Text('Open sheet'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showQuickDialog(context),
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Open dialog'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/command-center'),
                icon: const Icon(Icons.fullscreen_rounded),
                label: const Text('Full-screen overlay'),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('Snackbars and logs are wired for debug review.')));
                  debugPrint('info: Snackbar surface triggered from overview');
                },
                icon: const Icon(Icons.ad_units_rounded),
                label: const Text('Snackbar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = controller.compactMetrics || constraints.maxWidth < 720;
              if (controller.isRefreshingOverview) {
                return const DemoLoadingLines();
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metricTiles.map((Widget tile) {
                  return SizedBox(width: compact ? constraints.maxWidth : (constraints.maxWidth - 12) / 2, child: tile);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showQuickSheet(BuildContext context) {
    debugPrint('debug: Opened example modal sheet');
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: DemoSurface(
            radius: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Useful for validating modal sizing, route layers, and color inspection.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                const ListTile(leading: Icon(Icons.route_rounded), title: Text('Route-aware modal surface')),
                const ListTile(leading: Icon(Icons.animation_rounded), title: Text('Animation-friendly content block')),
                const ListTile(
                    leading: Icon(Icons.layers_clear_rounded), title: Text('Backdrop and clipping diagnostics')),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuickDialog(BuildContext context) {
    debugPrint('warn: Opened overview confirmation dialog');
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ship diagnostics build?'),
          content:
              const Text('This dialog exists to validate spacing, typography, accessibility, and overlay stacking.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Acknowledge')),
          ],
        );
      },
    );
  }
}

class _ModulesPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DemoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const DemoSectionHeader(eyebrow: 'Coverage', title: 'Tool-specific showcase map'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 560
                      ? 2
                      : 1;
              final double tileWidth = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: demoModules.map((DemoModule module) {
                  return SizedBox(
                    width: tileWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pushNamed('/module-detail', arguments: module),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(color: DemoTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: DemoTheme.accentGradient,
                                ),
                                child: Icon(module.icon, color: Colors.white, size: 20),
                              ),
                              const SizedBox(height: 14),
                              Text(module.title, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(module.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 10),
                              Text(module.surface, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.controller});

  final DemoAppController controller;

  @override
  Widget build(BuildContext context) {
    return DemoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DemoSectionHeader(
            eyebrow: 'Activity',
            title: 'Recent diagnostic events',
            action: DemoPill(
              label: controller.notificationsEnabled ? 'Notifications On' : 'Notifications Off',
              active: controller.notificationsEnabled,
              color: controller.notificationsEnabled ? DemoTheme.success : DemoTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          ...<({String title, String detail, Color color})>[
            (title: 'Route change', detail: 'Nested navigator pushed module detail', color: DemoTheme.success),
            (title: 'Async refresh', detail: 'Overview pull-to-refresh completed in 0.95s', color: DemoTheme.warning),
            (
              title: 'Overlay',
              detail: 'Modal sheet and full-screen command center both available',
              color: DemoTheme.accent
            ),
            (
              title: 'State',
              detail: 'Workspace supports optimistic pinning and incremental load',
              color: Color(0xFF5A9BFF)
            ),
          ].map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(999)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(item.detail, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DiagnosticLayoutShowcase extends StatelessWidget {
  const _DiagnosticLayoutShowcase({required this.controller});

  final DemoAppController controller;

  @override
  Widget build(BuildContext context) {
    return DemoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DemoSectionHeader(
            eyebrow: 'Layout',
            title: 'Nested spacing and constrained surfaces',
            action: Switch(value: controller.adaptiveGrid, onChanged: controller.toggleAdaptiveGrid),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool split = controller.adaptiveGrid && constraints.maxWidth > 760;
              final Widget inspectorStack = Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: _NestedDebugCard(color: DemoTheme.warning, title: 'Header metrics')),
                      const SizedBox(width: 12),
                      Expanded(child: _NestedDebugCard(color: DemoTheme.accent, title: 'Density controls')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _NestedDebugCard(color: DemoTheme.success, title: 'Adaptive status matrix', height: 184),
                ],
              );
              final Widget side = Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: _LegendPill(label: 'Min 320 px')),
                      const SizedBox(width: 8),
                      Expanded(child: _LegendPill(label: 'Max 560 px')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const DemoEmptyState(
                    title: 'Inspect me with Debug Paint',
                    message: 'Padding, border, alignment, and nested clipping are intentional here for layout tooling.',
                    icon: Icons.center_focus_strong_rounded,
                  ),
                ],
              );
              if (split) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 6, child: inspectorStack),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: side),
                  ],
                );
              }
              return Column(children: <Widget>[inspectorStack, const SizedBox(height: 16), side]);
            },
          ),
        ],
      ),
    );
  }
}

class _NestedDebugCard extends StatelessWidget {
  const _NestedDebugCard({required this.color, required this.title, this.height = 118});

  final Color color;
  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DemoTheme.border),
        color: Colors.white.withValues(alpha: 0.025),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: List<Widget>.generate(3, (int index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: color.withValues(alpha: 0.10 + (index * 0.04)),
                          border: Border.all(color: color.withValues(alpha: 0.28)),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: DemoTheme.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DemoTheme.textSecondary)),
    );
  }
}

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.controller, required this.onMenuTap});

  final DemoAppController controller;
  final VoidCallback onMenuTap;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  late final TabController _tabController;
  String _selectedTeam = workspaceTeams.first;
  String _selectedPriority = 'High';
  bool _notifyWatchers = true;
  double _confidence = 0.72;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DemoAppController controller = widget.controller;
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final List<DemoTaskItem> filtered = controller.filteredTasks();
        return RefreshIndicator(
          onRefresh: controller.refreshTasks,
          color: DemoTheme.accent,
          child: DemoPage(
            title: 'Workspace',
            subtitle: 'Forms, lists, filters, validation, optimistic updates, and empty/error/success states.',
            onMenuTap: widget.onMenuTap,
            trailing: DemoPill(
              label: '${filtered.length} visible',
              active: true,
              color: DemoTheme.warning,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildControlsBar(context, controller),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool split = constraints.maxWidth > 860;
                    final Widget form = _buildFormPanel(context, controller);
                    final Widget state = _buildStatePanel(context, controller, filtered);
                    if (split) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 5, child: form),
                          const SizedBox(width: 16),
                          Expanded(flex: 6, child: state),
                        ],
                      );
                    }
                    return Column(children: <Widget>[form, const SizedBox(height: 16), state]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlsBar(BuildContext context, DemoAppController controller) {
    return DemoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const DemoSectionHeader(eyebrow: 'Filters', title: 'Search, status, sort, and segmented views'),
          const SizedBox(height: 16),
          TextField(
            onChanged: controller.setSearchQuery,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search by task id, title, or owner',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: taskStatuses.map((String status) {
              return DemoPill(
                label: status,
                active: controller.selectedStatus == status,
                color: DemoTheme.warning,
                onTap: () => controller.setStatus(status),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: controller.selectedSort,
                  items: sortModes
                      .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      controller.setSort(value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Sort mode'),
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Demonstrates pointer-based affordances and overlay positioning.',
                child: DemoPill(label: 'Tooltip Surface', active: true, color: DemoTheme.accent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: DemoTheme.accent.withValues(alpha: 0.18),
            ),
            dividerColor: Colors.transparent,
            labelColor: DemoTheme.textPrimary,
            unselectedLabelColor: DemoTheme.textSecondary,
            tabs: const <Widget>[
              Tab(text: 'Form'),
              Tab(text: 'List'),
              Tab(text: 'States'),
            ],
          ),
          SizedBox(
            height: 220,
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _PreviewPanel(title: 'Validated inputs', icon: Icons.fact_check_rounded),
                _PreviewPanel(title: 'Sectioned queue', icon: Icons.view_agenda_rounded),
                _PreviewPanel(title: 'Recovery states', icon: Icons.refresh_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context, DemoAppController controller) {
    return DemoSurface(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DemoSectionHeader(eyebrow: 'Form', title: 'Create a diagnostic task'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task title'),
              validator: (String? value) {
                if (value == null || value.trim().length < 6) {
                  return 'Use at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedTeam,
              decoration: const InputDecoration(labelText: 'Owner team'),
              items: workspaceTeams
                  .map((String team) => DropdownMenuItem<String>(value: team, child: Text(team)))
                  .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _selectedTeam = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Implementation notes'),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(value: 'High', label: Text('High')),
                      ButtonSegment<String>(value: 'Medium', label: Text('Medium')),
                      ButtonSegment<String>(value: 'Low', label: Text('Low')),
                    ],
                    selected: <String>{_selectedPriority},
                    onSelectionChanged: (Set<String> value) => setState(() => _selectedPriority = value.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Confidence threshold ${(100 * _confidence).round()}%', style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: _confidence,
              onChanged: (double value) => setState(() => _confidence = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _notifyWatchers,
              onChanged: (bool value) => setState(() => _notifyWatchers = value),
              title: const Text('Notify watchers'),
              subtitle: const Text('Emits logs and snackbar on submit.'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: controller.notificationsEnabled,
              onChanged: (bool? value) => controller.toggleNotifications(value ?? false),
              title: const Text('Mirror to activity stream'),
              subtitle: const Text('Shared state example through controller.'),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              collapsedIconColor: DemoTheme.textSecondary,
              iconColor: DemoTheme.textPrimary,
              title: const Text('Advanced flags'),
              subtitle: const Text('Accordion surface for spacing and nested layout inspection.'),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              children: const <Widget>[
                ListTile(title: Text('Deferred fetch after submit')),
                ListTile(title: Text('Record analytics event')),
                ListTile(title: Text('Attach design review metadata')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) {
                        debugPrint('warn: Workspace form validation failed');
                        return;
                      }
                      await controller.submitTask(
                        title: _titleController.text.trim(),
                        owner: _selectedTeam,
                        priority: _selectedPriority,
                        notifyWatchers: _notifyWatchers,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      _titleController.clear();
                      _notesController.clear();
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(content: Text('Task created successfully')));
                    },
                    child: const Text('Create task'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      _titleController.clear();
                      _notesController.clear();
                      debugPrint('debug: Workspace form reset');
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatePanel(BuildContext context, DemoAppController controller, List<DemoTaskItem> filtered) {
    return DemoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DemoSectionHeader(
            eyebrow: 'List states',
            title: 'Sectioned queue, empty state, and pagination',
            action: DemoPill(
              label: controller.showTaskSuccess ? 'Success State' : 'Interactive',
              active: true,
              color: controller.showTaskSuccess ? DemoTheme.success : DemoTheme.warning,
            ),
          ),
          const SizedBox(height: 16),
          if (controller.isRefreshingTasks)
            const DemoLoadingLines()
          else ...<Widget>[
            if (filtered.isEmpty)
              DemoEmptyState(
                title: 'No matching tasks',
                message: 'Change the query or filter set to restore rows and verify empty-state handling.',
                icon: Icons.search_off_rounded,
                action: OutlinedButton(
                  onPressed: () {
                    controller.setSearchQuery('');
                    controller.setStatus('All');
                  },
                  child: const Text('Clear filters'),
                ),
              )
            else ...<Widget>[
              for (final String bucket in <String>['High', 'Medium', 'Low']) ...<Widget>[
                Text(bucket.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 10),
                ...filtered.where((DemoTaskItem item) => item.priority == bucket).map((DemoTaskItem task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).pushNamed('/task-detail', arguments: task),
                        child: Ink(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(color: DemoTheme.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(task.id,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(color: DemoTheme.warning)),
                                        const SizedBox(width: 8),
                                        DemoPill(label: task.status, color: DemoTheme.accent, active: true),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(task.summary, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                children: <Widget>[
                                  IconButton(
                                    onPressed: () => controller.togglePinned(task),
                                    icon: Icon(task.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                                  ),
                                  Text(task.owner, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 6),
              if (controller.isLoadingMoreTasks)
                const DemoLoadingLines()
              else
                OutlinedButton.icon(
                  onPressed: controller.loadMoreTasks,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Load more rows'),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DemoSurface(
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: DemoTheme.accent.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: DemoTheme.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          ],
        ),
      ),
    );
  }
}

class NetworkLabScreen extends StatelessWidget {
  const NetworkLabScreen({super.key, required this.controller, required this.onMenuTap});

  final DemoAppController controller;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return RefreshIndicator(
          onRefresh: controller.refreshNetworkDashboard,
          color: DemoTheme.accent,
          child: DemoPage(
            title: 'Network Lab',
            subtitle: 'Real requests for the inspector: success, payloads, retries, burst traffic, and failures.',
            onMenuTap: onMenuTap,
            trailing: DemoPill(
              label: controller.networkHealth,
              color: controller.networkHealth == 'Nominal' ? DemoTheme.success : DemoTheme.warning,
              active: true,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DemoSectionHeader(
                        eyebrow: 'Summary',
                        title: 'Request dashboard',
                        action: OutlinedButton.icon(
                          onPressed: controller.isRefreshingNetwork ? null : controller.refreshNetworkDashboard,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (controller.networkError != null)
                        DemoEmptyState(
                          title: 'Network summary degraded',
                          message: controller.networkError!,
                          icon: Icons.cloud_off_rounded,
                          action:
                              FilledButton(onPressed: controller.refreshNetworkDashboard, child: const Text('Retry')),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                DemoMetricTile(
                                    label: 'Health',
                                    value: controller.networkHealth,
                                    caption: 'Derived from a live GET request during refresh',
                                    tint: DemoTheme.success),
                                DemoMetricTile(
                                    label: 'Captured',
                                    value: controller.networkRuns.length.toString(),
                                    caption: 'Real `http` package requests logged for inspector validation',
                                    tint: DemoTheme.warning),
                                DemoMetricTile(
                                    label: 'Retry Paths',
                                    value: '3',
                                    caption: 'Backoff scenario available for error recovery',
                                    tint: DemoTheme.accent),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.03),
                                border: Border.all(color: DemoTheme.border),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.http_rounded, color: DemoTheme.warning),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      controller.networkActivityLabel == 'Idle'
                                          ? 'Scenarios below perform live HTTP requests so FlutterLens Network Inspector can capture them.'
                                          : controller.networkActivityLabel,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DemoSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DemoSectionHeader(
                        eyebrow: 'Scenarios',
                        title: 'Run inspector-friendly requests',
                        action: DemoPill(
                          label: controller.isNetworkBusy ? 'Busy' : 'Ready',
                          active: true,
                          color: controller.isNetworkBusy ? DemoTheme.warning : DemoTheme.success,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final int columns = constraints.maxWidth > 920
                              ? 3
                              : constraints.maxWidth > 580
                                  ? 2
                                  : 1;
                          final double itemWidth = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: networkScenarios.map((NetworkScenario scenario) {
                              return SizedBox(
                                width: itemWidth,
                                child: DemoSurface(
                                  padding: const EdgeInsets.all(16),
                                  radius: 20,
                                  borderColor: scenario.tint.withValues(alpha: 0.22),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      DemoPill(label: scenario.method, color: scenario.tint, active: true),
                                      const SizedBox(height: 12),
                                      Text(scenario.title, style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 6),
                                      Text(scenario.description, style: Theme.of(context).textTheme.bodyMedium),
                                      const SizedBox(height: 10),
                                      Text(
                                        scenario.endpoint,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: DemoTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 16),
                                      FilledButton(
                                        onPressed:
                                            controller.isNetworkBusy ? null : () => controller.runScenario(scenario),
                                        child: const Text('Make HTTP call'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DemoSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const DemoSectionHeader(eyebrow: 'History', title: 'Recent request outcomes'),
                      const SizedBox(height: 16),
                      if (controller.networkRuns.isEmpty)
                        const DemoEmptyState(
                          title: 'No requests yet',
                          message: 'Run any scenario to populate the local activity stream and inspector surfaces.',
                          icon: Icons.wifi_tethering_off_rounded,
                        )
                      else
                        ...controller.networkRuns.take(8).map((NetworkRun run) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.03),
                                border: Border.all(color: DemoTheme.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: run.tint.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(run.method,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(run.title, style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 4),
                                        Text(run.endpoint, style: Theme.of(context).textTheme.bodySmall),
                                        const SizedBox(height: 4),
                                        Text(run.detail, style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(run.statusLabel,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: run.tint)),
                                      const SizedBox(height: 4),
                                      Text(TimeOfDay.fromDateTime(run.startedAt).format(context),
                                          style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MotionLabScreen extends StatefulWidget {
  const MotionLabScreen({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  State<MotionLabScreen> createState() => _MotionLabScreenState();
}

class _MotionLabScreenState extends State<MotionLabScreen> with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _barsController;
  bool _expanded = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _barsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _barsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Curve resolvedCurve = FlutterLensAnimationCurveScope.resolve(context, Curves.easeInOutCubic);
    return DemoPage(
      title: 'Motion Lab',
      subtitle: 'Animation gallery for curve overrides, performance overlays, repaints, and visual timing checks.',
      onMenuTap: widget.onMenuTap,
      trailing: DemoPill(label: '60 FPS target', active: true, color: DemoTheme.success),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DemoSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoSectionHeader(
                  eyebrow: 'Hero motion',
                  title: 'Explicit + implicit animation stack',
                  action: OutlinedButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(_expanded ? Icons.compress_rounded : Icons.expand_rounded),
                    label: Text(_expanded ? 'Compress' : 'Expand'),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedContainer(
                  duration: Duration(milliseconds: (900 / _speed).round()),
                  curve: resolvedCurve,
                  height: _expanded ? 280 : 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0x1AF7A250), Color(0x12E24A79), Color(0x245A3386)],
                    ),
                    border: Border.all(color: DemoTheme.borderStrong),
                  ),
                  child: AnimatedBuilder(
                    animation: Listenable.merge(<Listenable>[_orbitController, _pulseController]),
                    builder: (BuildContext context, _) {
                      return CustomPaint(
                        painter: _OrbitPainter(progress: _orbitController.value, pulse: _pulseController.value),
                        child: Stack(
                          children: <Widget>[
                            Align(
                              alignment: Alignment.center,
                              child: Transform.scale(
                                scale: 0.92 + (_pulseController.value * 0.08),
                                child: Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: DemoTheme.accentGradient,
                                    boxShadow: const <BoxShadow>[
                                      BoxShadow(color: Color.fromRGBO(226, 74, 121, 0.35), blurRadius: 32),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                                top: 18,
                                left: 18,
                                child: DemoPill(label: 'Orbit', active: true, color: DemoTheme.warning)),
                            const Positioned(
                                bottom: 18,
                                right: 18,
                                child: DemoPill(label: 'Pulse', active: true, color: DemoTheme.accent)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('Playback speed ${_speed.toStringAsFixed(2)}x', style: Theme.of(context).textTheme.bodyMedium),
                Slider(
                  value: _speed,
                  min: 0.5,
                  max: 1.8,
                  onChanged: (double value) {
                    setState(() => _speed = value);
                    _orbitController.duration = Duration(milliseconds: (10000 / value).round());
                    _orbitController.repeat();
                    _barsController.duration = Duration(milliseconds: (1600 / value).round());
                    _barsController.repeat(reverse: true);
                    debugPrint('debug: Motion speed adjusted to ${value.toStringAsFixed(2)}');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool split = constraints.maxWidth > 820;
              final Widget chart = DemoSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const DemoSectionHeader(eyebrow: 'Painter', title: 'Animated frame cost bars'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: AnimatedBuilder(
                        animation: _barsController,
                        builder: (BuildContext context, _) {
                          return CustomPaint(
                            painter: _BarsPainter(progress: _barsController.value),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
              final Widget list = DemoSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const DemoSectionHeader(eyebrow: 'Scrollable', title: 'Animated activity stream'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: 18,
                        itemBuilder: (BuildContext context, int index) {
                          return RepaintBoundary(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: FadeTransition(
                                opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulseController),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: Colors.white.withValues(alpha: 0.03 + (index.isEven ? 0.02 : 0.0)),
                                    border: Border.all(color: DemoTheme.border),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: index.isEven ? DemoTheme.success : DemoTheme.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text('Frame event ${index + 1}',
                                              style: Theme.of(context).textTheme.bodyMedium)),
                                      const Icon(Icons.chevron_right_rounded, color: DemoTheme.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
              if (split) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: chart),
                    const SizedBox(width: 16),
                    Expanded(child: list),
                  ],
                );
              }
              return Column(children: <Widget>[chart, const SizedBox(height: 16), list]);
            },
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller, required this.onMenuTap});

  final DemoAppController controller;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final ThemeData theme = Theme.of(context);
    final double textScale = mediaQuery.textScaler.scale(14) / 14;
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return DemoPage(
          title: 'Settings + Device',
          subtitle: 'Dense information panels, device context, and semantic color surfaces for inspection.',
          onMenuTap: onMenuTap,
          trailing: DemoPill(
              label: '${mediaQuery.size.width.round()} x ${mediaQuery.size.height.round()}',
              active: true,
              color: DemoTheme.success),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const DemoSectionHeader(eyebrow: 'Device', title: 'Runtime snapshot'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        DemoMetricTile(
                            label: 'Brightness',
                            value: mediaQuery.platformBrightness.name,
                            caption: 'Useful beside FlutterLens device details',
                            tint: DemoTheme.warning),
                        DemoMetricTile(
                            label: 'Text Scale',
                            value: textScale.toStringAsFixed(2),
                            caption: 'Accessibility-aware layout coverage',
                            tint: DemoTheme.success),
                        DemoMetricTile(
                            label: 'Padding',
                            value: mediaQuery.padding.top.round().toString(),
                            caption: 'Top inset for safe-area diagnostics',
                            tint: DemoTheme.accent),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DemoSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const DemoSectionHeader(eyebrow: 'Semantic palette', title: 'Color-rich inspection surface'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const <Widget>[
                        _ColorSwatchCard(title: 'Success', color: DemoTheme.success),
                        _ColorSwatchCard(title: 'Warning', color: DemoTheme.warning),
                        _ColorSwatchCard(title: 'Accent', color: DemoTheme.accent),
                        _ColorSwatchCard(title: 'Deep', color: DemoTheme.accentDeep),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: controller.notificationsEnabled,
                      onChanged: controller.toggleNotifications,
                      title: Text('Runtime notifications', style: theme.textTheme.titleMedium),
                      subtitle: Text('Shared state toggle for logs and reactive surfaces.',
                          style: theme.textTheme.bodyMedium),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: controller.adaptiveGrid,
                      onChanged: controller.toggleAdaptiveGrid,
                      title: Text('Adaptive layouts', style: theme.textTheme.titleMedium),
                      subtitle:
                          Text('Flips between stacked and split compositions.', style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({super.key, required this.module});

  final DemoModule module;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(module.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26))),
                ],
              ),
              const SizedBox(height: 20),
              DemoSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(module.subtitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(module.surface, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    const Text(
                        'This detail route exists primarily to validate nested navigation, screen naming, safe-area handling, and dense text presentation in the same visual language.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task});

  final DemoTaskItem task;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(task.id, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26))),
                ],
              ),
              const SizedBox(height: 16),
              DemoSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(task.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(task.summary, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        DemoPill(label: task.priority, active: true, color: DemoTheme.warning),
                        DemoPill(label: task.status, active: true, color: DemoTheme.accent),
                        DemoPill(label: task.owner, active: true, color: DemoTheme.success),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DemoTheme.canvas,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.4,
                    colors: <Color>[Color(0x22E24A79), Color(0x00090B0E)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Command Center', style: Theme.of(context).textTheme.headlineMedium)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const DemoSurface(
                    child: Text(
                        'Full-screen overlay route for validating layer stacks, focus transitions, large tap targets, and route labels.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchCard extends StatelessWidget {
  const _ColorSwatchCard({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _DemoDrawer extends StatelessWidget {
  const _DemoDrawer({required this.controller});

  final DemoAppController controller;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: DemoTheme.panel,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const DemoSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('FlutterLens', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text(
                        'Side panel for drawer coverage, compact settings, and secondary navigation. It mirrors the product tone instead of introducing a different visual mode.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.settings_suggest_rounded),
                title: const Text('Notifications'),
                trailing:
                    Switch.adaptive(value: controller.notificationsEnabled, onChanged: controller.toggleNotifications),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_customize_rounded),
                title: const Text('Adaptive grids'),
                trailing: Switch.adaptive(value: controller.adaptiveGrid, onChanged: controller.toggleAdaptiveGrid),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoBottomBar extends StatelessWidget {
  const _DemoBottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String)> items = <(IconData, String)>[
      (Icons.space_dashboard_rounded, 'Overview'),
      (Icons.view_kanban_rounded, 'Workspace'),
      (Icons.wifi_tethering_rounded, 'Network'),
      (Icons.animation_rounded, 'Motion'),
      (Icons.tune_rounded, 'Settings'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: DemoSurface(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          radius: 26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.indexed.map((entry) {
              final bool active = entry.$1 == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(entry.$1),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: active ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(entry.$2.$1, color: active ? DemoTheme.textPrimary : DemoTheme.textMuted, size: 20),
                        const SizedBox(height: 6),
                        Text(entry.$2.$2,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: active ? DemoTheme.textPrimary : DemoTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.progress, required this.pulse});

  final double progress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);
    final Offset center = size.center(Offset.zero);
    final List<double> radii = <double>[52, 88, 122];
    for (final double radius in radii) {
      canvas.drawCircle(center, radius, track);
    }

    final List<Color> colors = <Color>[DemoTheme.warning, DemoTheme.accent, DemoTheme.success];
    for (int index = 0; index < radii.length; index++) {
      final double angle = (progress * math.pi * 2) + (index * 1.65);
      final Offset point = center + Offset(math.cos(angle), math.sin(angle)) * radii[index];
      final Paint dot = Paint()..color = colors[index].withValues(alpha: 0.6 + (pulse * 0.4));
      canvas.drawCircle(point, 9 + (pulse * 2), dot);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return progress != oldDelegate.progress || pulse != oldDelegate.pulse;
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.06);
    for (int index = 1; index <= 4; index++) {
      final double y = size.height - ((size.height / 5) * index);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    final double barWidth = size.width / 14;
    for (int index = 0; index < 12; index++) {
      final double phase = ((progress + (index * 0.08)) % 1.0);
      final double height = 28 + (math.sin(phase * math.pi * 2) + 1) * 54;
      final Rect rect = Rect.fromLTWH(index * (barWidth + 8), size.height - height, barWidth, height);
      final Paint fill = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[Color(0xFFF7A250), Color(0xFFE24A79)],
        ).createShader(rect);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), fill);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
