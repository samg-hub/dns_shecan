import 'package:flutter/services.dart';

class DNSService {
  static const platform = MethodChannel('com.shecan.dns/control');

  Future<bool> getStatus(List<String> servers) async {
    try {
      final bool result = await platform.invokeMethod('getStatus', {
        'servers': servers,
      });
      return result;
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

  Future<void> connect(List<String> servers, {bool force = false}) async {
    await platform.invokeMethod('connect', {
      'servers': servers,
      'force': force,
    });
  }

  Future<void> disconnect() async {
    await platform.invokeMethod('disconnect');
  }
}
