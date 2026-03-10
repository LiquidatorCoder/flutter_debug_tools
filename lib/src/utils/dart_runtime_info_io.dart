import 'dart:io';

String getDartRuntimeVersion() {
  final String version = Platform.version;
  if (version.isEmpty) return 'runtime';
  return version.split(' ').first;
}
