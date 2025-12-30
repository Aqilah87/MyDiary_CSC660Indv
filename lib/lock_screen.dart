// lib/lock_screen.dart
// BIOMETRIC ONLY - NO PIN

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  bool _isAuthenticating = true;
  String _statusMessage = 'Checking biometric...';
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Checking device capabilities...';
    });

    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      print('🔐 Biometric Check:');
      print('   canCheckBiometrics: $canCheckBiometrics');
      print('   isDeviceSupported: $isDeviceSupported');
      
      if (canCheckBiometrics && isDeviceSupported) {
        setState(() {
          _biometricAvailable = true;
          _statusMessage = 'Biometric available';
        });
        
        await Future.delayed(Duration(milliseconds: 500));
        _authenticate();
      } else {
        setState(() {
          _biometricAvailable = false;
          _isAuthenticating = false;
          _statusMessage = 'Biometric not available on this device';
        });
      }
    } catch (e) {
      print('❌ Error checking biometric: $e');
      setState(() {
        _biometricAvailable = false;
        _isAuthenticating = false;
        _statusMessage = 'Error checking biometric: $e';
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your diary',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
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
        _statusMessage = 'Authentication error: $e';
      });
    }
  }

  void _goToHome() {
    print('✅ Authentication successful - navigating to HomePage');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.childAfterUnlock ?? HomePage(),
      ),
    );
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
                  Icon(
                    Icons.fingerprint,
                    size: 100,
                    color: Colors.white,
                  ),
                  SizedBox(height: 30),
                  
                  Text(
                    'Dear Diary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 50),
                  
                  if (_isAuthenticating)
                    Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Authenticating...',
                          style: TextStyle(color: Colors.white70),
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
                              style: TextStyle(fontSize: 18),
                            ),
                            onPressed: _authenticate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF764ba2),
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.orange,
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
                              SizedBox(height: 20),
                              ElevatedButton(
                                child: Text('Skip to App'),
                                onPressed: _goToHome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
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