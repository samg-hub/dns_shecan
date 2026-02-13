import 'package:flutter/services.dart';

class DNSService {
  static const platform = MethodChannel('com.shecan.dns/control');

  Future<bool> getStatus() async {
    try {
      return await platform.invokeMethod('getStatus');
    } on PlatformException {
      return false;
    }
  }

  Future<String> getActiveInterface() async {
    try {
      return await platform.invokeMethod('getActiveInterface');
    } on PlatformException {
      return 'Unknown';
    }
  }

  Future<void> connect({bool force = false}) async {
    await platform.invokeMethod('connect', {'force': force});
  }

  Future<void> disconnect() async {
    await platform.invokeMethod('disconnect');
  }
}
