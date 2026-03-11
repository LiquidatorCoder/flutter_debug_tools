import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_debug_tools/src/debug_network_store.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel_styles.dart';
import 'package:flutter_debug_tools/src/view/flutter_lens_theme.dart';

class DebugNetworkViewer extends StatefulWidget {
  const DebugNetworkViewer({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<DebugNetworkViewer> createState() => _DebugNetworkViewerState();
}

class _DebugNetworkViewerState extends State<DebugNetworkViewer> {
  _NetworkFilter _selectedFilter = _NetworkFilter.all;
  DebugNetworkEntry? _selectedEntry;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: flutterLensTheme(context),
      child: Scaffold(
        backgroundColor: DebugToolsPanelStyles.sheetFill,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Text(
                          'Network Inspector',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: DebugToolsPanelStyles.textPrimary,
                            fontFamily: flutterLensFontFamily,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _HeaderButton(
                        icon: Icons.clear_rounded,
                        onTap: widget.onTap,
                      ),
                      const SizedBox(width: 8),
                      _HeaderButton(
                        icon: Icons.delete_outline_rounded,
                        onTap: DebugNetworkStore.instance.clear,
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      scrollDirection: Axis.horizontal,
                      itemCount: _NetworkFilter.values.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final _NetworkFilter filter = _NetworkFilter.values[index];
                        final bool isSelected = filter == _selectedFilter;
                        return _FilterChip(
                          title: _filterTitle(filter),
                          isSelected: isSelected,
                          filter: filter,
                          onTap: () => setState(() => _selectedFilter = filter),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 32,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: DebugToolsPanelStyles.sheetFill,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: ValueListenableBuilder<List<DebugNetworkEntry>>(
                              valueListenable: DebugNetworkStore.instance.entries,
                              builder: (context, entries, _) {
                                if (entries.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        'No network requests captured yet.\nThis currently tracks dart:io HttpClient traffic.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.45,
                                          color: Color(0xA3FFFFFF),
                                          fontFamily: flutterLensFontFamily,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final List<DebugNetworkEntry> filtered = _filterEntries(entries);
                                if (filtered.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        'No ${_filterTitle(_selectedFilter).toLowerCase()} requests yet.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.45,
                                          color: Color(0xA3FFFFFF),
                                          fontFamily: flutterLensFontFamily,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.only(top: 6, bottom: 10),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.only(left: 56, right: 16),
                                    child: Divider(
                                      height: 1,
                                      color: Colors.white.withValues(alpha: 0.04),
                                    ),
                                  ),
                                  itemBuilder: (context, index) {
                                    final DebugNetworkEntry entry = filtered[filtered.length - 1 - index];
                                    return _NetworkRow(
                                      entry: entry,
                                      onTap: () => setState(() {
                                        _selectedEntry = entry;
                                      }),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedEntry != null) ...[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      _selectedEntry = null;
                    }),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.48),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _NetworkDetailsSheet(
                    entry: _selectedEntry!,
                    onClose: () => setState(() {
                      _selectedEntry = null;
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<DebugNetworkEntry> _filterEntries(List<DebugNetworkEntry> entries) {
    if (_selectedFilter == _NetworkFilter.all) {
      return entries;
    }

    return entries.where((entry) {
      switch (_selectedFilter) {
        case _NetworkFilter.all:
          return true;
        case _NetworkFilter.pending:
          return entry.state == DebugNetworkRequestState.pending;
        case _NetworkFilter.success:
          return entry.state == DebugNetworkRequestState.success;
        case _NetworkFilter.failure:
          return entry.state == DebugNetworkRequestState.failure;
        case _NetworkFilter.retries:
          return entry.retryCount > 0;
      }
    }).toList();
  }

  String _filterTitle(_NetworkFilter filter) {
    switch (filter) {
      case _NetworkFilter.all:
        return 'All';
      case _NetworkFilter.pending:
        return 'Pending';
      case _NetworkFilter.success:
        return 'Success';
      case _NetworkFilter.failure:
        return 'Failure';
      case _NetworkFilter.retries:
        return 'Retries';
    }
  }
}

enum _NetworkFilter { all, pending, success, failure, retries }

class _NetworkRow extends StatelessWidget {
  const _NetworkRow({
    required this.entry,
    required this.onTap,
  });

  final DebugNetworkEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String time = _formatTime(entry.startedAt);
    final String duration = _formatDuration(entry.duration);
    final String status =
        entry.statusCode?.toString() ?? (entry.state == DebugNetworkRequestState.pending ? '...' : '--');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBadge(
                status: status,
                statusCode: entry.statusCode,
                requestState: entry.state,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _pathText(entry.url),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: flutterLensFontFamily,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.28),
                            fontFamily: flutterLensFontFamily,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.url.host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.55),
                        fontFamily: flutterLensFontFamily,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _RequestTypeChip(method: entry.method),
                        _MetaPill(
                          label: duration,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        if (entry.retryCount > 0)
                          _MetaPill(
                            label: 'RETRY ${entry.retryCount}',
                            color: const Color(0xFFF7A250),
                          ),
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

  String _pathText(Uri url) {
    final String path = url.path.isEmpty ? '/' : url.path;
    return url.hasQuery ? '$path?${url.query}' : path;
  }

  String _formatDuration(Duration? value) {
    if (value == null) {
      return 'PENDING';
    }
    final int ms = value.inMilliseconds;
    return '${ms}ms';
  }

  String _formatTime(DateTime timestamp) {
    final String hour = timestamp.hour.toString().padLeft(2, '0');
    final String minute = timestamp.minute.toString().padLeft(2, '0');
    final String second = timestamp.second.toString().padLeft(2, '0');
    final String centisecond = (timestamp.millisecond ~/ 10).toString().padLeft(2, '0');
    return '$hour:$minute:$second.$centisecond';
  }
}

class _NetworkDetailsSheet extends StatelessWidget {
  const _NetworkDetailsSheet({
    required this.entry,
    required this.onClose,
  });

  final DebugNetworkEntry entry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final _StatusBadgeStyle statusStyle = _badgeStyleForStatus(entry.statusCode, entry.state);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      decoration: const BoxDecoration(
        color: DebugToolsPanelStyles.sheetFill,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: flutterLensFontFamily,
                  ),
                ),
                const Spacer(),
                _HeaderButton(
                  icon: Icons.content_copy_rounded,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: _copyPayload(entry)));
                    if (!context.mounted) {
                      return;
                    }
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger
                      ?..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Request copied to clipboard'),
                          duration: Duration(milliseconds: 1200),
                        ),
                      );
                  },
                ),
                const SizedBox(width: 8),
                _HeaderButton(
                  icon: Icons.clear_rounded,
                  onTap: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _DetailCard(
                  title: 'Overview',
                  icon: Icons.info_outline_rounded,
                  accent: const Color(0xFFF7A250),
                  child: _OverviewTable(
                    entry: entry,
                    statusStyle: statusStyle,
                  ),
                ),
                const SizedBox(height: 10),
                _DetailCard(
                  title: 'Request Headers',
                  icon: Icons.send_rounded,
                  accent: const Color(0xFF4ADE80),
                  child: _HeadersTable(headers: entry.requestHeaders),
                ),
                const SizedBox(height: 10),
                _DetailCard(
                  title: 'Response Headers',
                  icon: Icons.inbox_rounded,
                  accent: const Color(0xFFE24A79),
                  child: _HeadersTable(headers: entry.responseHeaders),
                ),
                const SizedBox(height: 10),
                _DetailCard(
                  title: 'Request Payload',
                  icon: Icons.data_object_rounded,
                  accent: const Color(0xFF4ADE80),
                  headerAction: _CardActionButton(
                    icon: Icons.content_copy_rounded,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: entry.requestBody ?? '--'),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      messenger
                        ?..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Request payload copied'),
                            duration: Duration(milliseconds: 1100),
                          ),
                        );
                    },
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _PlainTextBlock(text: entry.requestBody ?? '--'),
                  ),
                ),
                const SizedBox(height: 10),
                _DetailCard(
                  title: 'Response Payload',
                  icon: Icons.dataset_linked_rounded,
                  accent: const Color(0xFFE24A79),
                  headerAction: _CardActionButton(
                    icon: Icons.content_copy_rounded,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: entry.responseBody ?? '--'),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      messenger
                        ?..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Response payload copied'),
                            duration: Duration(milliseconds: 1100),
                          ),
                        );
                    },
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _PlainTextBlock(text: entry.responseBody ?? '--'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _copyPayload(DebugNetworkEntry entry) {
  return '${_copyOverview(entry)}\n\nREQUEST HEADERS\n${_headersText(entry.requestHeaders)}\n\nRESPONSE HEADERS\n${_headersText(entry.responseHeaders)}\n\nREQUEST PAYLOAD\n${entry.requestBody ?? '--'}\n\nRESPONSE PAYLOAD\n${entry.responseBody ?? '--'}';
}

String _copyOverview(DebugNetworkEntry entry) {
  final String state = entry.state.name.toUpperCase();
  final String started = entry.startedAt.toIso8601String();
  final String ended = entry.endedAt?.toIso8601String() ?? '--';
  final String duration = entry.duration?.inMilliseconds.toString() ?? '--';
  final String status = entry.statusCode?.toString() ?? '--';
  final String retries = entry.retryCount.toString();
  final String error = entry.error ?? '--';

  return 'Method: ${entry.method}\nURL: ${entry.url}\nState: $state\nStatus: $status\nRetries: $retries\nStarted: $started\nEnded: $ended\nDuration(ms): $duration\nError: $error';
}

String _headersText(Map<String, String> values) {
  if (values.isEmpty) {
    return '--';
  }
  final List<String> lines = values.entries.map((e) => '${e.key}: ${e.value}').toList();
  lines.sort();
  return lines.join('\n');
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.headerAction,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        color: Colors.white.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    shape: BoxShape.rectangle,
                    color: accent.withValues(alpha: 0.08),
                    border: Border.all(color: accent.withValues(alpha: 0.42)),
                  ),
                  child: Icon(icon, size: 13, color: accent),
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: accent,
                    fontFamily: flutterLensFontFamily,
                  ),
                ),
                if (headerAction != null) ...[
                  const Spacer(),
                  headerAction!,
                ],
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(
            icon,
            size: 13,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}

class _OverviewTable extends StatelessWidget {
  const _OverviewTable({
    required this.entry,
    required this.statusStyle,
  });

  final DebugNetworkEntry entry;
  final _StatusBadgeStyle statusStyle;

  @override
  Widget build(BuildContext context) {
    final String stateLabel = entry.state.name.toUpperCase();
    final String statusLabel = entry.statusCode?.toString() ?? '--';
    final String duration = entry.duration == null ? 'PENDING' : '${entry.duration!.inMilliseconds}ms';

    return Column(
      children: [
        _OverviewUrlRow(url: entry.url.toString()),
        _OverviewRow(label: 'Method', trailing: _InlineChip(label: entry.method, color: Colors.white)),
        _OverviewRow(
          label: 'State',
          trailing: _InlineChip(
            label: stateLabel,
            color: statusStyle.textColor,
            fill: statusStyle.textColor.withValues(alpha: 0.12),
          ),
        ),
        _OverviewRow(
          label: 'Status',
          trailing: _InlineChip(
            label: statusLabel,
            color: statusStyle.textColor,
            fill: statusStyle.textColor.withValues(alpha: 0.12),
          ),
        ),
        _OverviewRow(label: 'Retries', value: entry.retryCount.toString()),
        _OverviewRow(
          label: 'Duration',
          showDivider: false,
          trailing: _InlineChip(
            label: duration,
            color: Colors.white.withValues(alpha: 0.72),
            fill: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.label,
    this.value,
    this.trailing,
    this.showDivider = true,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: showDivider ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  fontFamily: flutterLensFontFamily,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing ??
                    Text(
                      value ?? '--',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w600,
                        fontFamily: flutterLensFontFamily,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewUrlRow extends StatelessWidget {
  const _OverviewUrlRow({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'URL',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                fontFamily: flutterLensFontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              url,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4ADE80),
                fontWeight: FontWeight.w600,
                fontFamily: flutterLensFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadersTable extends StatelessWidget {
  const _HeadersTable({required this.headers});

  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty) {
      return Text(
        '--',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.72),
          fontFamily: flutterLensFontFamily,
        ),
      );
    }

    final List<MapEntry<String, String>> entries = headers.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: entries.asMap().entries.map((indexedEntry) {
        final int index = indexedEntry.key;
        final MapEntry<String, String> entry = indexedEntry.value;
        final bool isLast = index == entries.length - 1;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isLast ? Colors.transparent : Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFF7A250),
                      fontWeight: FontWeight.w600,
                      fontFamily: flutterLensFontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontFamily: flutterLensFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({
    required this.label,
    required this.color,
    this.fill,
  });

  final String label;
  final Color color;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: fill ?? color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w800,
          color: color,
          fontFamily: flutterLensFontFamily,
        ),
      ),
    );
  }
}

class _PlainTextBlock extends StatelessWidget {
  const _PlainTextBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: const TextStyle(
        fontSize: 10,
        height: 1.45,
        color: Color(0xE6FFFFFF),
        fontFamily: flutterLensFontFamily,
        fontFeatures: [
          FontFeature.tabularFigures(),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.statusCode,
    required this.requestState,
  });

  final String status;
  final int? statusCode;
  final DebugNetworkRequestState requestState;

  @override
  Widget build(BuildContext context) {
    final _StatusBadgeStyle style = _badgeStyleForStatus(statusCode, requestState);

    return Container(
      width: 34,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: style.gradient,
        color: style.fillColor,
        border: Border.all(color: style.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: status.length >= 3 ? 9 : 10,
          fontWeight: FontWeight.w900,
          color: style.textColor,
          fontFamily: flutterLensFontFamily,
          fontFeatures: const [
            FontFeature.tabularFigures(),
          ],
        ),
      ),
    );
  }
}

_StatusBadgeStyle _badgeStyleForStatus(
  int? code,
  DebugNetworkRequestState state,
) {
  if (code != null) {
    if (code >= 500 || code >= 400) {
      return const _StatusBadgeStyle(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x33EF4444),
            Color(0x11EF4444),
          ],
        ),
        borderColor: Color(0x66EF4444),
        textColor: Color(0xFFEF4444),
      );
    }

    if (code >= 300) {
      return const _StatusBadgeStyle(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x33F7A250),
            Color(0x11F7A250),
          ],
        ),
        borderColor: Color(0x66F7A250),
        textColor: Color(0xFFF7A250),
      );
    }

    if (code >= 200) {
      return const _StatusBadgeStyle(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x334ADE80),
            Color(0x114ADE80),
          ],
        ),
        borderColor: Color(0x664ADE80),
        textColor: Color(0xFF4ADE80),
      );
    }
  }

  if (state == DebugNetworkRequestState.failure) {
    return const _StatusBadgeStyle(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x33EF4444),
          Color(0x11EF4444),
        ],
      ),
      borderColor: Color(0x66EF4444),
      textColor: Color(0xFFEF4444),
    );
  }

  if (state == DebugNetworkRequestState.pending) {
    return const _StatusBadgeStyle(
      gradient: DebugToolsPanelStyles.accentGradient,
      borderColor: Colors.transparent,
      textColor: Colors.white,
    );
  }

  return _StatusBadgeStyle(
    fillColor: Colors.white.withValues(alpha: 0.06),
    borderColor: Colors.white.withValues(alpha: 0.14),
    textColor: Colors.white.withValues(alpha: 0.78),
  );
}

class _StatusBadgeStyle {
  const _StatusBadgeStyle({
    this.gradient,
    this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  final Gradient? gradient;
  final Color? fillColor;
  final Color borderColor;
  final Color textColor;
}

class _RequestTypeChip extends StatelessWidget {
  const _RequestTypeChip({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        method,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.white.withValues(alpha: 0.88),
          fontFamily: flutterLensFontFamily,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
          fontFamily: flutterLensFontFamily,
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: DebugToolsPanelStyles.textPrimary.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.title,
    required this.isSelected,
    required this.filter,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final _NetworkFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? _selectedBorderColor(filter) : Colors.white.withValues(alpha: 0.10),
            ),
            gradient: isSelected ? _selectedGradient(filter) : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
          ),
          child: Center(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                color:
                    isSelected ? _selectedTextColor(filter) : DebugToolsPanelStyles.textPrimary.withValues(alpha: 0.45),
                fontFamily: flutterLensFontFamily,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Gradient _selectedGradient(_NetworkFilter value) {
    switch (value) {
      case _NetworkFilter.success:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x334ADE80),
            Color(0x114ADE80),
          ],
        );
      case _NetworkFilter.failure:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x33EF4444),
            Color(0x11EF4444),
          ],
        );
      case _NetworkFilter.pending:
      case _NetworkFilter.retries:
      case _NetworkFilter.all:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7A250), Color(0xFFE24A79), Color(0xFF5A3386)],
        );
    }
  }

  Color _selectedBorderColor(_NetworkFilter value) {
    switch (value) {
      case _NetworkFilter.success:
        return const Color(0x664ADE80);
      case _NetworkFilter.failure:
        return const Color(0x66EF4444);
      case _NetworkFilter.pending:
      case _NetworkFilter.retries:
      case _NetworkFilter.all:
        return Colors.transparent;
    }
  }

  Color _selectedTextColor(_NetworkFilter value) {
    switch (value) {
      case _NetworkFilter.success:
        return const Color(0xFF4ADE80);
      case _NetworkFilter.failure:
        return const Color(0xFFEF4444);
      case _NetworkFilter.pending:
      case _NetworkFilter.retries:
      case _NetworkFilter.all:
        return Colors.white.withValues(alpha: 0.98);
    }
  }
}
