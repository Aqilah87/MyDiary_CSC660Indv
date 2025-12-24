// lib/services/auth_service.dart
import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check device supports biometrics or device credential
  Future<bool> canAuthenticate() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Trigger authentication prompt (biometric or device credential fallback)
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your diary',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow device PIN/fallback at OS level
        ),
      );
      return didAuthenticate;
    } catch (e) {
      // handle exceptions if you want (log)
      return false;
    }
  }
}
