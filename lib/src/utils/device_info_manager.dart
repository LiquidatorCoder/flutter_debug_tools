import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class DeviceInfoManager {
  DeviceInfoManager._privateConstructor();

  static final DeviceInfoManager _instance =
      DeviceInfoManager._privateConstructor();

  static DeviceInfoManager get instance => _instance;

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // Method to get screen size
  Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  // Method to get screen density
  double getScreenDensity(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  // Method to get detailed device information
  Future<Map<String, dynamic>> getDeviceDetails() async {
    Map<String, dynamic> deviceData = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceData = _readAndroidBuildData(androidInfo);
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceData = _readIosDeviceInfo(iosInfo);
      }
    } catch (exception) {
      deviceData = {'Error': 'Failed to get device info'};
    }

    return deviceData;
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'Security Patch Version': build.version.securityPatch,
      'SDK Version': build.version.sdkInt,
      'Release Version': build.version.release,
      'Board': build.board,
      'Brand': build.brand,
      'Device': build.device,
      'Display': build.display,
      'Model': build.model,
      'Product': build.product,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'Name': data.name,
      'System Name': data.systemName,
      'System Version': data.systemVersion,
      'Model': data.model,
      'Localized Model': data.localizedModel,
      'Identifier For Vendor': data.identifierForVendor,
    };
  }
}
