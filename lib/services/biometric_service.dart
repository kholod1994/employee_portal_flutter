import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../core/storage/safe_storage.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const SafeStorage _storage = SafeStorage();

  static const String _keyBiometricEnabled = 'biometric_login_enabled';
  static const String _keyBiometricUser = 'biometric_saved_user';
  static const String _keyBiometricPass = 'biometric_saved_pass';

  /// Check if hardware supports biometrics and has enrolled credentials
  static Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometric canAuthenticate error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  /// Get list of available biometric types (Fingerprint, Face, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Returns user-friendly Arabic label for the available biometrics
  static Future<String> getBiometricLabel() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) {
      if (types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong)) {
        return 'بصمة الإصبع أو الوجه';
      }
      return 'بصمة الوجه (Face ID)';
    }
    if (types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong)) {
      return 'بصمة الإصبع';
    }
    return 'البصمة الحيوية';
  }

  /// Check if the user previously enabled biometric login in settings
  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  /// Enable or disable biometric login
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
    if (!enabled) {
      await _storage.delete(key: _keyBiometricUser);
      await _storage.delete(key: _keyBiometricPass);
    }
  }

  /// Store credentials securely to allow background biometric login
  static Future<void> saveCredentials(String identifier, String password) async {
    await _storage.write(key: _keyBiometricUser, value: identifier);
    await _storage.write(key: _keyBiometricPass, value: password);
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  /// Retrieve stored credentials for biometric login
  static Future<Map<String, String>?> getSavedCredentials() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return null;
    final user = await _storage.read(key: _keyBiometricUser);
    final pass = await _storage.read(key: _keyBiometricPass);
    if (user != null && pass != null && user.isNotEmpty && pass.isNotEmpty) {
      return {'identifier': user, 'password': pass};
    }
    return null;
  }

  /// Check if credentials exist and biometric is enabled
  static Future<bool> hasSavedCredentials() async {
    final creds = await getSavedCredentials();
    return creds != null;
  }

  /// Trigger biometric authentication prompt
  static Future<bool> authenticate({
    String? localizedReason,
    bool biometricOnly = true,
  }) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason ?? 'يرجى تأكيد الهوية باستخدام البصمة أو الوجه',
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Authentication platform error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }
}
