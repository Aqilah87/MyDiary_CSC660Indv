// lib/screens/lock_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../pages/home_page.dart';

class LockScreen extends StatefulWidget {
  final Widget? childAfterUnlock;
  const LockScreen({Key? key, this.childAfterUnlock}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _authService = AuthService();

  bool _isAuthenticating = true;
  String _statusMessage = 'Checking authentication...';

  final TextEditingController _pinController = TextEditingController();
  String? savedPin;

  @override
  void initState() {
    super.initState();
    _loadPin();
    _startBiometricCheck();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    savedPin = prefs.getString('user_pin'); // ✅ CHANGED: user_pin_code -> user_pin
    setState(() {});
  }

  Future<void> _startBiometricCheck() async {
    setState(() {
      _isAuthenticating = true;
    });

    // Check device capability
    final bool available = await _authService.canAuthenticate();

    if (!available) {
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'Biometric not available.\nUse PIN instead.';
      });
      return;
    }

    // Try biometric
    final bool success = await _authService.authenticate();

    if (success) {
      _goToHome();
    } else {
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'Biometric failed.\nEnter PIN to unlock.';
      });
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.childAfterUnlock ?? HomePage(),
      ),
    );
  }

  Future<void> _checkPin() async {
    final enteredPin = _pinController.text.trim();

    // ✅ ADDED: Better validation
    if (enteredPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter PIN"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (savedPin == null || savedPin!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No PIN set. Please use biometric or contact support."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (enteredPin == savedPin) {
      // ✅ ADDED: Success feedback before navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PIN correct! Unlocking..."),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
      
      // Small delay for better UX
      await Future.delayed(Duration(milliseconds: 300));
      _goToHome();
    } else {
      // ✅ IMPROVED: Clear field and show error
      _pinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Incorrect PIN. Try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose(); // ✅ ADDED: Clean up controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: _isAuthenticating
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 18),
                      Text("Authenticating...", textAlign: TextAlign.center),
                    ],
                  )
                : SingleChildScrollView( // ✅ ADDED: Prevent overflow on small screens
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 80, color: Colors.purple),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 30),

                        // Fallback PIN UI
                        if (savedPin != null && savedPin!.isNotEmpty) ...[
                          TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                            textAlign: TextAlign.center, // ✅ IMPROVED: Center text
                            decoration: const InputDecoration(
                              labelText: "Enter 4-digit PIN",
                              border: OutlineInputBorder(),
                              counterText: "", // ✅ IMPROVED: Hide counter
                            ),
                            onSubmitted: (_) => _checkPin(), // ✅ ADDED: Submit on enter
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.lock_open),
                            label: const Text("Unlock with PIN"),
                            onPressed: _checkPin,
                          ),
                        ],

                        const SizedBox(height: 25),

                        // Retry biometric button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.fingerprint),
                          label: const Text("Try Biometric Again"),
                          onPressed: _startBiometricCheck,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
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