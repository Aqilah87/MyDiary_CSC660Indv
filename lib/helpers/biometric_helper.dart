import 'package:flutter/services.dart';

class BiometricHelper {
  static const platform = MethodChannel('biometric_channel');

  /// Check if device supports biometric authentication
  static Future<bool> canAuthenticate() async {
    try {
      final bool result = await platform.invokeMethod('canAuthenticate');
      print('🔍 BiometricHelper.canAuthenticate: $result');
      return result;
    } catch (e) {
      print('❌ Error checking biometric: $e');
      return false;
    }
  }

  /// Authenticate user with biometric
  static Future<bool> authenticate() async {
    try {
      print('🔐 Starting biometric authentication...');
      final bool result = await platform.invokeMethod('authenticate');
      print('✅ Authentication successful: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ Authentication error: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error: $e');
      return false;
    }
  }
}