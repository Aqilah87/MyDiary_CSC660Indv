// FILE: lib/screens/offline_status_widget.dart
// NO external package needed - uses dart:io only

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class SimpleOfflineStatusWidget extends StatefulWidget {
  @override
  _SimpleOfflineStatusWidgetState createState() => _SimpleOfflineStatusWidgetState();
}

class _SimpleOfflineStatusWidgetState extends State<SimpleOfflineStatusWidget> {
  bool _isOnline = true;
  bool _firstCheck = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Check every 5 seconds
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    bool isConnected = false;
    
    try {
      // Try to connect to Google DNS
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 3));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isConnected = true;
      }
    } on SocketException catch (_) {
      isConnected = false;
    } on TimeoutException catch (_) {
      isConnected = false;
    } catch (e) {
      isConnected = false;
    }

    if (mounted) {
      bool wasOnline = _isOnline;
      
      setState(() {
        _isOnline = isConnected;
      });

      // Show popup if status changed (not first load)
      if (!_firstCheck && wasOnline != isConnected) {
        _showStatusPopup(isConnected);
      }
      
      _firstCheck = false;
    }
  }

  void _showStatusPopup(bool isOnline) {
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOnline ? '✅ Back Online!' : '📡 Offline Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isOnline 
                        ? 'Internet connection restored'
                        : 'No internet • App works perfectly offline',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isOnline ? Colors.green[600] : Colors.orange[600],
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isOnline 
            ? Colors.green.withOpacity(0.12) 
            : Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isOnline 
              ? Colors.green.withOpacity(0.5) 
              : Colors.orange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Pulsing dot indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOnline ? Colors.green[600] : Colors.orange[600],
              boxShadow: [
                BoxShadow(
                  color: _isOnline 
                      ? Colors.green.withOpacity(0.6) 
                      : Colors.orange.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          
          // Status icon
          Icon(
            _isOnline ? Icons.cloud_done : Icons.cloud_off,
            size: 22,
            color: _isOnline ? Colors.green[700] : Colors.orange[700],
          ),
          SizedBox(width: 10),
          
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? '🟢 Online Mode' : '🟠 Offline Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  _isOnline 
                      ? 'Connected • Data saved locally'
                      : 'No Internet • App works perfectly',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isOnline ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}