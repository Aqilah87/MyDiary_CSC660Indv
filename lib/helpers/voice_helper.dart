import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceHelper {
  static final VoiceHelper _instance = VoiceHelper._internal();
  factory VoiceHelper() => _instance;
  VoiceHelper._internal();

  late stt.SpeechToText _speech;
  bool _isInitialized = false;
  bool _isListening = false;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _speech = stt.SpeechToText();
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Error initializing speech: $e');
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    
    // Request permission if not granted
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.isAvailable;
  }

  /// Start listening to voice input
  /// Returns true if listening started successfully
  Future<bool> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    String locale = 'en_US', // Change to 'ms_MY' for Malay
  }) async {
    // Check permission first
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      print('Microphone permission denied');
      return false;
    }

    // Initialize if not already
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('Speech recognition not initialized');
        return false;
      }
    }

    // Check if available
    final available = await isAvailable();
    if (!available) {
      print('Speech recognition not available');
      return false;
    }

    // Start listening
    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        localeId: locale,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        listenFor: Duration(seconds: 30), // Max listening duration
        pauseFor: Duration(seconds: 3), // Pause detection
      );
      
      _isListening = true;
      return true;
    } catch (e) {
      print('Error starting listening: $e');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get available locales
  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  /// Dispose resources
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
  }
}