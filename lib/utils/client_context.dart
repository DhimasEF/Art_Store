import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class ClientContext {
  static Map<String, String>? _cache;

  static Future<Map<String, String>> get() async {
    if (_cache != null) return _cache!;

    final deviceInfo = DeviceInfoPlugin();

    String device = "unknown";
    String platform = "unknown";

    if (kIsWeb) {
      platform = "web";
      device = "browser";
    } else {
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final a = await deviceInfo.androidInfo;
          device = "${a.brand} ${a.model}";
          platform = "android";
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final i = await deviceInfo.iosInfo;
          device = i.utsname.machine ?? "iOS";
          platform = "ios";
        }
      } catch (_) {}
    }

    String ip = "unknown";
    try {
      final res =
          await http.get(Uri.parse("https://api.ipify.org?format=json"));
      ip = jsonDecode(res.body)['ip'];
    } catch (_) {}

    _cache = {
      "ip": ip,
      "device": device,
      "platform": platform,
    };

    return _cache!;
  }
}
