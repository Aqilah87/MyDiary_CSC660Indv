// Simple offline status widget - displays online/offline indicator
// Uses dart:io for internet connectivity check (no external packages needed)
// Shows real-time connection status with automatic updates

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class SimpleOfflineStatusWidget extends StatefulWidget {
  @override
  _SimpleOfflineStatusWidgetState createState() => _SimpleOfflineStatusWidgetState();
}

class _SimpleOfflineStatusWidgetState extends State<SimpleOfflineStatusWidget> {
  bool _isOnline = true;      // Current connection status
  bool _firstCheck = true;    // Track if this is the first check (avoid popup on app start)
  Timer? _timer;              // Timer for periodic connection checks

  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Check connection every 5 seconds for real-time updates
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkConnection();
    });
  }

  // Check internet connection by attempting to reach Google DNS
  Future<void> _checkConnection() async {
    bool isConnected = false;
    
    try {
      // Try to lookup google.com with 3 second timeout
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 3));
      
      // If successful and has valid address, we're online
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isConnected = true;
      }
    } on SocketException catch (_) {
      // No internet connection
      isConnected = false;
    } on TimeoutException catch (_) {
      // Connection timeout
      isConnected = false;
    } catch (e) {
      // Any other error means offline
      isConnected = false;
    }

    if (mounted) {
      bool wasOnline = _isOnline;
      
      setState(() {
        _isOnline = isConnected;
      });

      // Show notification popup only if status changed (not on first load)
      if (!_firstCheck && wasOnline != isConnected) {
        _showStatusPopup(isConnected);
      }
      
      _firstCheck = false;
    }
  }

  // Display popup notification when connection status changes
  void _showStatusPopup(bool isOnline) {
    // Clear existing notifications first
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // WiFi icon
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
                  // Main status text
                  Text(
                    isOnline ? '✅ Back Online!' : '📡 Offline Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Descriptive message
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
        // Green for online, orange for offline
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
    _timer?.cancel(); // Cancel timer when widget disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400), // Smooth color transition
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // Light green/orange background based on status
        color: _isOnline 
            ? Colors.green.withOpacity(0.12) 
            : Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        // Border color matches status
        border: Border.all(
          color: _isOnline 
              ? Colors.green.withOpacity(0.5) 
              : Colors.orange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Pulsing dot indicator (visual feedback)
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
          
          // Cloud status icon
          Icon(
            _isOnline ? Icons.cloud_done : Icons.cloud_off,
            size: 22,
            color: _isOnline ? Colors.green[700] : Colors.orange[700],
          ),
          SizedBox(width: 10),
          
          // Status text and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main status
                Text(
                  _isOnline ? '🟢 Online Mode' : '🟠 Offline Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
                SizedBox(height: 3),
                // Status description
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