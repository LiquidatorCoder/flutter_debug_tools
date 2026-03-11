import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_debug_tools/src/debug_network_store.dart';

const int _maxCaptureBytes = 64 * 1024;

HttpOverrides? _previousOverrides;
bool _isInstalled = false;

void installDebugNetworkCapture() {
  if (_isInstalled) {
    return;
  }
  _isInstalled = true;
  _previousOverrides = HttpOverrides.current;
  HttpOverrides.global = _FlutterLensHttpOverrides(_previousOverrides);
}

class _FlutterLensHttpOverrides extends HttpOverrides {
  _FlutterLensHttpOverrides(this._delegate);

  final HttpOverrides? _delegate;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient baseClient = _delegate?.createHttpClient(context) ?? super.createHttpClient(context);
    return _DebugHttpClient(baseClient);
  }
}

class _DebugHttpClient implements HttpClient {
  _DebugHttpClient(this._inner);

  final HttpClient _inner;

  Future<HttpClientRequest> _wrap(String method, Uri url, Future<HttpClientRequest> futureRequest) async {
    final HttpClientRequest innerRequest = await futureRequest;
    return _DebugHttpClientRequest(
      inner: innerRequest,
      method: method,
      url: url,
    );
  }

  Uri _hostUri(String host, int port, String path) {
    final Uri? parsed = Uri.tryParse(path);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    return Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: path,
    );
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return _wrap(method, url, _inner.openUrl(method, url));
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return _wrap('GET', url, _inner.getUrl(url));
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return _wrap('POST', url, _inner.postUrl(url));
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return _wrap('PUT', url, _inner.putUrl(url));
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return _wrap('DELETE', url, _inner.deleteUrl(url));
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return _wrap('PATCH', url, _inner.patchUrl(url));
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return _wrap('HEAD', url, _inner.headUrl(url));
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    return _wrap(method, _hostUri(host, port, path), _inner.open(method, host, port, path));
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return _wrap('GET', _hostUri(host, port, path), _inner.get(host, port, path));
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return _wrap('POST', _hostUri(host, port, path), _inner.post(host, port, path));
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return _wrap('PUT', _hostUri(host, port, path), _inner.put(host, port, path));
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return _wrap('DELETE', _hostUri(host, port, path), _inner.delete(host, port, path));
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return _wrap('PATCH', _hostUri(host, port, path), _inner.patch(host, port, path));
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return _wrap('HEAD', _hostUri(host, port, path), _inner.head(host, port, path));
  }

  @override
  void close({bool force = false}) {
    _inner.close(force: force);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => _inner.noSuchMethod(invocation);
}

class _DebugHttpClientRequest implements HttpClientRequest {
  _DebugHttpClientRequest({
    required HttpClientRequest inner,
    required this.method,
    required this.url,
  }) : _inner = inner;

  final HttpClientRequest _inner;
  @override
  final String method;
  final Uri url;

  final BytesBuilder _requestBody = BytesBuilder(copy: false);
  bool _isCompleted = false;
  String? _requestId;

  String _ensureRequestStarted() {
    final String? existingId = _requestId;
    if (existingId != null) {
      return existingId;
    }
    final String id = DebugNetworkStore.instance.startRequest(
      method: method,
      url: url,
      requestHeaders: _flattenHeaders(_inner.headers),
      requestBody: _decodeBytes(_requestBody.takeBytes()),
    );
    _requestId = id;
    return id;
  }

  void _captureChunk(List<int> bytes) {
    final int existing = _requestBody.length;
    final int remaining = _maxCaptureBytes - existing;
    if (remaining <= 0 || bytes.isEmpty) {
      return;
    }
    if (bytes.length <= remaining) {
      _requestBody.add(bytes);
      return;
    }
    _requestBody.add(bytes.sublist(0, remaining));
  }

  @override
  void add(List<int> data) {
    _captureChunk(data);
    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _inner.addError(error, stackTrace);
  }

  @override
  Future<void> flush() {
    return _inner.flush();
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    return _inner.addStream(stream.map((chunk) {
      _captureChunk(chunk);
      return chunk;
    }));
  }

  @override
  void write(Object? obj) {
    final List<int> encoded = encoding.encode(obj?.toString() ?? 'null');
    _captureChunk(encoded);
    _inner.write(obj);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeln([Object? obj = '']) {
    write('${obj ?? ''}\n');
  }

  @override
  void writeCharCode(int charCode) {
    _captureChunk(<int>[charCode]);
    _inner.writeCharCode(charCode);
  }

  @override
  Future<HttpClientResponse> close() async {
    final String requestId = _ensureRequestStarted();
    try {
      final HttpClientResponse response = await _inner.close();
      if (_isCompleted) {
        return response;
      }
      _isCompleted = true;
      DebugNetworkStore.instance.completeRequest(
        id: requestId,
        statusCode: response.statusCode,
        responseHeaders: _flattenHeaders(response.headers),
      );
      return _DebugHttpClientResponse(
        inner: response,
        requestId: requestId,
      );
    } catch (error) {
      if (!_isCompleted) {
        _isCompleted = true;
        DebugNetworkStore.instance.failRequest(
          id: requestId,
          error: error.toString(),
        );
      }
      rethrow;
    }
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    final String requestId = _ensureRequestStarted();
    if (!_isCompleted) {
      _isCompleted = true;
      DebugNetworkStore.instance.failRequest(
        id: requestId,
        error: exception?.toString() ?? 'Request aborted',
      );
    }
    _inner.abort(exception, stackTrace);
  }

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding value) {
    _inner.encoding = value;
  }

  @override
  bool get followRedirects => _inner.followRedirects;

  @override
  set followRedirects(bool value) {
    _inner.followRedirects = value;
  }

  @override
  int get maxRedirects => _inner.maxRedirects;

  @override
  set maxRedirects(int value) {
    _inner.maxRedirects = value;
  }

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  set persistentConnection(bool value) {
    _inner.persistentConnection = value;
  }

  @override
  int get contentLength => _inner.contentLength;

  @override
  set contentLength(int value) {
    _inner.contentLength = value;
  }

  @override
  bool get bufferOutput => _inner.bufferOutput;

  @override
  set bufferOutput(bool value) {
    _inner.bufferOutput = value;
  }

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<HttpClientResponse> get done => _inner.done;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  Uri get uri => _inner.uri;

  @override
  dynamic noSuchMethod(Invocation invocation) => _inner.noSuchMethod(invocation);
}

class _DebugHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  _DebugHttpClientResponse({
    required HttpClientResponse inner,
    required this.requestId,
  }) : _inner = inner;

  final HttpClientResponse _inner;
  final String requestId;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> data)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final BytesBuilder responseBody = BytesBuilder(copy: false);

    return _inner.listen(
      (List<int> chunk) {
        _appendCapped(responseBody, chunk);
        if (onData != null) {
          onData(chunk);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        DebugNetworkStore.instance.failRequest(
          id: requestId,
          error: error.toString(),
          statusCode: _inner.statusCode,
          responseHeaders: _flattenHeaders(_inner.headers),
          responseBody: _decodeBytes(responseBody.takeBytes()),
        );
        if (onError != null) {
          if (onError is void Function(Object, StackTrace)) {
            onError(error, stackTrace);
          } else if (onError is void Function(Object)) {
            onError(error);
          }
        }
      },
      onDone: () {
        DebugNetworkStore.instance.completeRequest(
          id: requestId,
          statusCode: _inner.statusCode,
          responseHeaders: _flattenHeaders(_inner.headers),
          responseBody: _decodeBytes(responseBody.takeBytes()),
        );
        if (onDone != null) {
          onDone();
        }
      },
      cancelOnError: cancelOnError,
    );
  }

  @override
  X509Certificate? get certificate => _inner.certificate;

  @override
  HttpClientResponseCompressionState get compressionState => _inner.compressionState;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  int get contentLength => _inner.contentLength;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<Socket> detachSocket() {
    return _inner.detachSocket();
  }

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  List<RedirectInfo> get redirects => _inner.redirects;

  @override
  int get statusCode => _inner.statusCode;

  @override
  dynamic noSuchMethod(Invocation invocation) => _inner.noSuchMethod(invocation);
}

Map<String, String> _flattenHeaders(HttpHeaders headers) {
  final Map<String, String> result = <String, String>{};
  headers.forEach((name, values) {
    result[name] = values.join(', ');
  });
  return result;
}

void _appendCapped(BytesBuilder builder, List<int> bytes) {
  final int remaining = _maxCaptureBytes - builder.length;
  if (remaining <= 0 || bytes.isEmpty) {
    return;
  }
  if (bytes.length <= remaining) {
    builder.add(bytes);
  } else {
    builder.add(bytes.sublist(0, remaining));
  }
}

String? _decodeBytes(List<int> bytes) {
  if (bytes.isEmpty) {
    return null;
  }
  return utf8.decode(bytes, allowMalformed: true);
}
