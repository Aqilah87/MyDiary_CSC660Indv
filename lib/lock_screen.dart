// lib/lock_screen.dart
// BIOMETRIC ONLY - NO PIN

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'pages/home_page.dart';

class LockScreen extends StatefulWidget {
  final Widget? childAfterUnlock;
  const LockScreen({Key? key, this.childAfterUnlock}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isAuthenticating = false;
  String _statusMessage = 'Checking biometric...';
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    setState(() {
      _statusMessage = 'Checking device capabilities...';
    });

    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      print('🔐 Biometric Check:');
      print('   canCheckBiometrics: $canCheckBiometrics');
      print('   isDeviceSupported: $isDeviceSupported');
      
      if (canCheckBiometrics && isDeviceSupported) {
        // Check available biometrics
        final List<BiometricType> availableBiometrics = 
            await _localAuth.getAvailableBiometrics();
        
        print('   availableBiometrics: $availableBiometrics');
        
        if (availableBiometrics.isNotEmpty) {
          setState(() {
            _biometricAvailable = true;
            _statusMessage = 'Tap to authenticate';
          });
          
          // Auto-trigger authentication after short delay
          await Future.delayed(Duration(milliseconds: 800));
          if (mounted) {
            _authenticate();
          }
        } else {
          setState(() {
            _biometricAvailable = false;
            _statusMessage = 'No biometric enrolled on device';
          });
        }
      } else {
        setState(() {
          _biometricAvailable = false;
          _statusMessage = 'Biometric not available on this device';
        });
      }
    } catch (e) {
      print('❌ Error checking biometric: $e');
      setState(() {
        _biometricAvailable = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your diary',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern as fallback
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      print('🔐 Authentication result: $authenticated');

      if (authenticated) {
        _goToHome();
      } else {
        setState(() {
          _isAuthenticating = false;
          _statusMessage = 'Authentication failed. Try again.';
        });
      }
    } catch (e) {
      print('❌ Authentication error: $e');
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
      
      // Show error dialog
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Authentication Error'),
        content: Text(error),
        actions: [
          TextButton(
            child: Text('Retry'),
            onPressed: () {
              Navigator.pop(context);
              _authenticate();
            },
          ),
          if (!_isAuthenticating)
            TextButton(
              child: Text('Skip'),
              onPressed: () {
                Navigator.pop(context);
                _goToHome();
              },
            ),
        ],
      ),
    );
  }

  void _goToHome() {
    print('✅ Authentication successful - navigating to HomePage');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.childAfterUnlock ?? HomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fingerprint Icon
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // Title
                  Text(
                    'Dear Diary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  
                  // Subtitle
                  Text(
                    'Your private space',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // Status Message
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  
                  // Authentication Status/Button
                  if (_isAuthenticating)
                    Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Authenticating...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        if (_biometricAvailable)
                          ElevatedButton.icon(
                            icon: Icon(Icons.fingerprint, size: 28),
                            label: Text(
                              'Authenticate',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _authenticate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF764ba2),
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                            ),
                          )
                        else
                          Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.orange.shade300,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Biometric authentication not available',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Please enroll fingerprint in device settings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 30),
                              ElevatedButton.icon(
                                icon: Icon(Icons.arrow_forward),
                                label: Text('Continue to App'),
                                onPressed: _goToHome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}