import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_stub.dart'
    if (dart.library.html) 'storage_web.dart'
    if (dart.library.io) 'storage_io.dart';

class SafeStorage {
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  static final Map<String, String> _memoryFallback = {};

  const SafeStorage();

  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      await delete(key: key);
      return;
    }
    _memoryFallback[key] = value;
    if (kIsWeb) {
      await setStorageItem(key, value);
      return;
    }
    try {
      await _secure.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      final webVal = await getStorageItem(key);
      if (webVal != null) return webVal;
      return _memoryFallback[key];
    }
    try {
      final secureVal = await _secure.read(key: key);
      if (secureVal != null) return secureVal;
    } catch (_) {}
    return _memoryFallback[key];
  }

  Future<void> delete({required String key}) async {
    _memoryFallback.remove(key);
    if (kIsWeb) {
      await removeStorageItem(key);
      return;
    }
    try {
      await _secure.delete(key: key);
    } catch (_) {}
  }
}

