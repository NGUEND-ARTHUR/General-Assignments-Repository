import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const _deviceIdKey = 'bound_device_id';
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return '${info.id}_${info.model}_${info.brand}';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_platform';
  }

  /// Binds this device to a user account. Returns false if already bound to another user.
  Future<bool> bindDeviceToUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingBinding = prefs.getString(_deviceIdKey);

    if (existingBinding != null && existingBinding != userId) {
      return false; // Device already bound to a different user
    }

    await prefs.setString(_deviceIdKey, userId);
    return true;
  }

  Future<String?> getBoundUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  Future<bool> isDeviceBoundToUser(String userId) async {
    final boundUser = await getBoundUserId();
    return boundUser == userId;
  }

  Future<void> unbindDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }
}
