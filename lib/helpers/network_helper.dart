import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class NetworkHelper {
  static final NetworkHelper _instance = NetworkHelper._internal();
  factory NetworkHelper() => _instance;
  NetworkHelper._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connectivity
  /// Returns true if connected to WiFi or Mobile Data
  Future<bool> isConnected() async {
    try {
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      
      // Check if connected to WiFi or Mobile Data
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Alias for isConnected() - Same functionality
  /// Use this in FutureBuilder for cleaner code
  Future<bool> isOnline() async {
    return await isConnected();
  }

  /// Check if device has internet connectivity AND can reach internet
  /// More reliable than just checking connectivity
  /// Returns true if can actually access internet
  Future<bool> hasInternetAccess() async {
    try {
      // First check basic connectivity
      final bool connected = await isConnected();
      if (!connected) return false;

      // Then verify actual internet access by pinging Google
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking internet access: $e');
      return false;
    }
  }

  /// Stream to listen for connectivity changes
  /// Use this to update UI when connection status changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Get current connection type
  /// Returns 'WiFi', 'Mobile', 'None', or 'Unknown'
  Future<String> getConnectionType() async {
    try {
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return 'Mobile';
      } else if (connectivityResult.contains(ConnectivityResult.none)) {
        return 'None';
      }
      return 'Unknown';
    } catch (e) {
      print('Error getting connection type: $e');
      return 'Unknown';
    }
  }

  /// Check if specifically connected to WiFi
  Future<bool> isWiFiConnected() async {
    try {
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.wifi);
    } catch (e) {
      print('Error checking WiFi: $e');
      return false;
    }
  }

  /// Check if specifically connected to Mobile Data
  Future<bool> isMobileDataConnected() async {
    try {
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile);
    } catch (e) {
      print('Error checking mobile data: $e');
      return false;
    }
  }
}