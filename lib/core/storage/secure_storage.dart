import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gaweflutter/core/constants/app_constants.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage();

  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Helper methods
  static Future<void> saveToken(String token) async {
    await write(AppConstants.keyToken, token);
  }

  static Future<String?> getToken() async {
    return await read(AppConstants.keyToken);
  }

  static Future<void> deleteToken() async {
    await delete(AppConstants.keyToken);
  }

  static Future<void> saveDeviceId(String deviceId) async {
    await write(AppConstants.keyDeviceId, deviceId);
  }

  static Future<String?> getDeviceId() async {
    return await read(AppConstants.keyDeviceId);
  }

  static Future<void> saveUser(String userJson) async {
    await write(AppConstants.keyUser, userJson);
  }

  static Future<String?> getUser() async {
    return await read(AppConstants.keyUser);
  }

  static Future<void> deleteUser() async {
    await delete(AppConstants.keyUser);
  }
}

