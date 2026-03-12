import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_debug_tools/flutter_debug_tools.dart';
import 'package:http/http.dart' as http;

class CapturedHttpClient extends http.BaseClient {
  CapturedHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String requestId = DebugNetworkStore.instance.startRequest(
      method: request.method,
      url: request.url,
      requestHeaders: Map<String, String>.from(request.headers),
      requestBody: _requestBody(request),
    );

    try {
      final http.StreamedResponse response = await _inner.send(request);
      final Uint8List responseBytes = await response.stream.toBytes();
      final String? responseBody = _decodeBody(responseBytes, response.headers);

      DebugNetworkStore.instance.completeRequest(
        id: requestId,
        statusCode: response.statusCode,
        responseHeaders: Map<String, String>.from(response.headers),
        responseBody: responseBody,
      );

      return http.StreamedResponse(
        Stream<List<int>>.value(responseBytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (error) {
      DebugNetworkStore.instance.failRequest(
        id: requestId,
        error: error.toString(),
      );
      rethrow;
    }
  }

  String? _requestBody(http.BaseRequest request) {
    if (request is http.Request) {
      return request.body.isEmpty ? null : request.body;
    }
    if (request is http.MultipartRequest) {
      final Map<String, dynamic> payload = <String, dynamic>{
        'fields': request.fields,
        'files': request.files
            .map(
              (http.MultipartFile file) => <String, dynamic>{
                'field': file.field,
                'filename': file.filename,
                'length': file.length,
                'contentType': file.contentType.toString(),
              },
            )
            .toList(),
      };
      return jsonEncode(payload);
    }
    return null;
  }

  String? _decodeBody(Uint8List bytes, Map<String, String> headers) {
    if (bytes.isEmpty) {
      return null;
    }

    final String contentType = headers.entries
        .firstWhere(
          (MapEntry<String, String> entry) => entry.key.toLowerCase() == 'content-type',
          orElse: () => const MapEntry<String, String>('', ''),
        )
        .value
        .toLowerCase();

    if (contentType.contains('application/json') || contentType.contains('text/') || contentType.contains('utf-8')) {
      return utf8.decode(bytes, allowMalformed: true);
    }

    return 'Binary payload (${bytes.length} bytes)';
  }

  @override
  void close() {
    _inner.close();
  }
}
