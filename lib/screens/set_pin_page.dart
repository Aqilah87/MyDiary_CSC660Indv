import 'package:flutter/material.dart';

class SetPinPage extends StatefulWidget {
  @override
  _SetPinPageState createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isError = false;

  void _onNumberPressed(String number) {
    if (!_isConfirming) {
      // First PIN entry
      if (_pin.length < 4) {
        setState(() {
          _pin += number;
          _isError = false;
        });

        // Move to confirmation after 4 digits
        if (_pin.length == 4) {
          setState(() {
            _isConfirming = true;
          });
        }
      }
    } else {
      // Confirm PIN entry
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += number;
          _isError = false;
        });

        // Auto-verify when 4 digits entered
        if (_confirmPin.length == 4) {
          _verifyAndReturn();
        }
      }
    }
  }

  void _onDeletePressed() {
    if (!_isConfirming) {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _isError = false;
        });
      }
    } else {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          _isError = false;
        });
      }
    }
  }

  void _verifyAndReturn() {
    if (_pin == _confirmPin) {
      // ✅ PINs match! Return the PIN value
      print('✅ PIN matched! Returning: $_pin');
      Navigator.pop(context, _pin); // Return PIN to SettingsPage
    } else {
      // ❌ PINs don't match
      print('❌ PINs do not match');
      setState(() {
        _isError = true;
        _confirmPin = '';
        _pin = '';
        _isConfirming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PINs do not match! Try again'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onCancelPressed() {
    print('❌ User cancelled PIN setup');
    Navigator.pop(context, null); // Return null to indicate cancellation
  }

  @override
  Widget build(BuildContext context) {
    String currentPin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Set PIN'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _onCancelPressed,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                _isConfirming ? Icons.check_circle_outline : Icons.lock_outline,
                size: 80,
                color: _isConfirming ? Colors.green : Theme.of(context).primaryColor,
              ),
              SizedBox(height: 20),

              // Title
              Text(
                _isConfirming ? 'Confirm PIN' : 'Set Your PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

              // Subtitle
              Text(
                _isConfirming
                    ? 'Re-enter your 4-digit PIN'
                    : 'Enter a 4-digit PIN to secure your diary',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 50),

              // PIN Dots Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < currentPin.length
                          ? (_isConfirming ? Colors.green : Theme.of(context).primaryColor)
                          : Colors.grey[300],
                      border: Border.all(
                        color: _isError ? Colors.red : (_isConfirming ? Colors.green : Colors.blue),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 60),

              // Number Pad
              Column(
                children: [
                  _buildNumberRow(['1', '2', '3']),
                  SizedBox(height: 20),
                  _buildNumberRow(['4', '5', '6']),
                  SizedBox(height: 20),
                  _buildNumberRow(['7', '8', '9']),
                  SizedBox(height: 20),
                  _buildNumberRow(['', '0', 'delete']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number == '') {
          return SizedBox(width: 70, height: 70);
        } else if (number == 'delete') {
          return _buildDeleteButton();
        } else {
          return _buildNumberButton(number);
        }
      }).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[400]!),
          color: Theme.of(context).cardColor,
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDeletePressed,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[400]!),
          color: Theme.of(context).cardColor,
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
          ),
        ),
      ),
    );
  }
}