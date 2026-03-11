import 'package:flutter/foundation.dart';

enum DebugNetworkRequestState {
  pending,
  success,
  failure,
}

class DebugNetworkEntry {
  const DebugNetworkEntry({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
    required this.state,
    this.endedAt,
    this.statusCode,
    this.requestHeaders = const <String, String>{},
    this.responseHeaders = const <String, String>{},
    this.requestBody,
    this.responseBody,
    this.error,
    this.retryCount = 0,
  });

  final String id;
  final String method;
  final Uri url;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DebugNetworkRequestState state;
  final int? statusCode;
  final Map<String, String> requestHeaders;
  final Map<String, String> responseHeaders;
  final String? requestBody;
  final String? responseBody;
  final String? error;
  final int retryCount;

  Duration? get duration {
    final DateTime? end = endedAt;
    if (end == null) {
      return null;
    }
    return end.difference(startedAt);
  }

  DebugNetworkEntry copyWith({
    DateTime? endedAt,
    DebugNetworkRequestState? state,
    int? statusCode,
    Map<String, String>? requestHeaders,
    Map<String, String>? responseHeaders,
    Object? requestBody = _sentinel,
    Object? responseBody = _sentinel,
    Object? error = _sentinel,
  }) {
    return DebugNetworkEntry(
      id: id,
      method: method,
      url: url,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      state: state ?? this.state,
      statusCode: statusCode ?? this.statusCode,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      requestBody: identical(requestBody, _sentinel) ? this.requestBody : requestBody as String?,
      responseBody: identical(responseBody, _sentinel) ? this.responseBody : responseBody as String?,
      error: identical(error, _sentinel) ? this.error : error as String?,
      retryCount: retryCount,
    );
  }
}

class DebugNetworkStore {
  DebugNetworkStore._();

  static final DebugNetworkStore instance = DebugNetworkStore._();
  static const int _maxEntries = 200;

  final ValueNotifier<List<DebugNetworkEntry>> entries = ValueNotifier<List<DebugNetworkEntry>>(<DebugNetworkEntry>[]);

  int _nextId = 1;
  final Map<String, String> _requestFingerprintById = <String, String>{};
  final Map<String, DebugNetworkRequestState> _lastStateByFingerprint = <String, DebugNetworkRequestState>{};
  final Map<String, int> _retryCountByFingerprint = <String, int>{};

  String startRequest({
    required String method,
    required Uri url,
    required Map<String, String> requestHeaders,
    String? requestBody,
  }) {
    final String id = (_nextId++).toString();
    final String fingerprint = '${method.toUpperCase()} ${url.toString()}';
    final bool isRetry = _lastStateByFingerprint[fingerprint] == DebugNetworkRequestState.failure;
    final int retryCount = isRetry ? (_retryCountByFingerprint[fingerprint] ?? 0) + 1 : 0;

    _requestFingerprintById[id] = fingerprint;

    _appendEntry(
      DebugNetworkEntry(
        id: id,
        method: method.toUpperCase(),
        url: url,
        startedAt: DateTime.now(),
        state: DebugNetworkRequestState.pending,
        requestHeaders: requestHeaders,
        requestBody: _trimPayload(requestBody),
        retryCount: retryCount,
      ),
    );

    return id;
  }

  void completeRequest({
    required String id,
    int? statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
  }) {
    _updateEntry(
      id,
      (entry) {
        final DebugNetworkRequestState finalState =
            (statusCode ?? 0) >= 400 ? DebugNetworkRequestState.failure : DebugNetworkRequestState.success;
        _updateRetryMaps(entry.id, finalState);
        return entry.copyWith(
          endedAt: DateTime.now(),
          statusCode: statusCode,
          state: finalState,
          responseHeaders: responseHeaders,
          responseBody: _trimPayload(responseBody),
          error: finalState == DebugNetworkRequestState.failure
              ? entry.error ?? (statusCode != null ? 'HTTP $statusCode' : 'Request failed')
              : null,
        );
      },
    );
  }

  void failRequest({
    required String id,
    required String error,
    int? statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
  }) {
    _updateEntry(
      id,
      (entry) {
        _updateRetryMaps(entry.id, DebugNetworkRequestState.failure);
        return entry.copyWith(
          endedAt: DateTime.now(),
          state: DebugNetworkRequestState.failure,
          statusCode: statusCode,
          responseHeaders: responseHeaders,
          responseBody: _trimPayload(responseBody),
          error: error,
        );
      },
    );
  }

  void clear() {
    entries.value = <DebugNetworkEntry>[];
    _requestFingerprintById.clear();
    _lastStateByFingerprint.clear();
    _retryCountByFingerprint.clear();
  }

  void _appendEntry(DebugNetworkEntry entry) {
    final List<DebugNetworkEntry> next = List<DebugNetworkEntry>.from(entries.value)..add(entry);
    if (next.length > _maxEntries) {
      next.removeRange(0, next.length - _maxEntries);
    }
    entries.value = next;
  }

  void _updateEntry(String id, DebugNetworkEntry Function(DebugNetworkEntry entry) update) {
    final List<DebugNetworkEntry> current = entries.value;
    final int index = current.indexWhere((entry) => entry.id == id);
    if (index == -1) {
      return;
    }

    final List<DebugNetworkEntry> next = List<DebugNetworkEntry>.from(current);
    next[index] = update(next[index]);
    entries.value = next;
  }

  void _updateRetryMaps(String id, DebugNetworkRequestState finalState) {
    final String? fingerprint = _requestFingerprintById[id];
    if (fingerprint == null) {
      return;
    }
    _lastStateByFingerprint[fingerprint] = finalState;
    if (finalState == DebugNetworkRequestState.success) {
      _retryCountByFingerprint[fingerprint] = 0;
    } else if (finalState == DebugNetworkRequestState.failure) {
      final DebugNetworkEntry? entry = entries.value.cast<DebugNetworkEntry?>().firstWhere(
            (value) => value?.id == id,
            orElse: () => null,
          );
      _retryCountByFingerprint[fingerprint] = entry?.retryCount ?? 0;
    }
  }

  String? _trimPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return payload;
    }

    const int maxChars = 10000;
    if (payload.length <= maxChars) {
      return payload;
    }
    return '${payload.substring(0, maxChars)}\n...[truncated]';
  }
}

const Object _sentinel = Object();
