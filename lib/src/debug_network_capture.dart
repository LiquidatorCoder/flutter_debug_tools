import 'network_capture/debug_network_capture_stub.dart'
    if (dart.library.io) 'network_capture/debug_network_capture_io.dart' as impl;

void installDebugNetworkCapture() => impl.installDebugNetworkCapture();
