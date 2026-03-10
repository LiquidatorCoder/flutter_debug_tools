import 'dart_runtime_info_stub.dart'
    if (dart.library.io) 'dart_runtime_info_io.dart' as runtime;

String getDartRuntimeVersion() => runtime.getDartRuntimeVersion();
