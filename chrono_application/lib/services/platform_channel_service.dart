// chrono_application/lib/services/platform_channel_service.dart

import 'dart:async';
import 'dart:convert'; // <--- ADD THIS IMPORT!
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart'; // Import the channel constants

// Helper for logging
void _log(String message) {
  if (kDebugMode) {
    debugPrint('[PlatformChannelService] $message');
  }
}

class PlatformChannelService {
  // 1. Define the Channels
  // Used for two-way communication (method calls)
  static const MethodChannel _methodChannel = MethodChannel(
    METHOD_CHANNEL_NAME,
  );

  // Used for streaming data (native -> dart)
  static const EventChannel _eventChannel = EventChannel(EVENT_CHANNEL_NAME);

  // 2. Stream for Location Data
  // We expose a stream of map data for the UI to listen to.
  // The native code will push events to this stream.
  Stream<Map<String, dynamic>> get locationStream {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      // The event is typically a JSON string or a Map from native
      if (event is Map) {
        // Assuming native sends a map of location data
        return Map<String, dynamic>.from(event);
      }
      // Safely decode a JSON string if native sends one
      try {
        // The jsonDecode function is now available here
        return jsonDecode(event.toString()) as Map<String, dynamic>;
      } catch (_) {
        _log('Error decoding event: $event');
        return {};
      }
    });
  }

  /// ----------------------------------------------------
  /// 3. Method Calls (Dart -> Native)
  /// ----------------------------------------------------

  /// Initializes the ChronosNav SDK on the native platform.
  Future<bool> initializeSDK() async {
    try {
      _log('Attempting to initialize ChronosNav SDK...');
      // Arguments required for native initialization (e.g., API key, config)
      final bool success = await _methodChannel.invokeMethod('initializeSDK', {
        // You would pass any necessary config parameters here
        'apiKey': 'YOUR_CHRONOSNAV_API_KEY_HERE',
      });
      _log('SDK initialization success: $success');
      // Note: The PlatformException catch block expects a boolean return,
      // but invokeMethod can return null or other types.
      // Ensure the native code returns a valid boolean.
      return success;
    } on PlatformException catch (e) {
      _log('Failed to initialize SDK: ${e.message}');
      return false;
    }
  }

  /// Tells the native platform to start receiving real-time location updates.
  Future<void> startPositioning() async {
    try {
      _log('Calling native startPositioning...');
      await _methodChannel.invokeMethod('startPositioning');
    } on PlatformException catch (e) {
      _log('Failed to start positioning: ${e.message}');
    }
  }

  /// Tells the native platform to stop location updates.
  Future<void> stopPositioning() async {
    try {
      _log('Calling native stopPositioning...');
      await _methodChannel.invokeMethod('stopPositioning');
    } on PlatformException catch (e) {
      _log('Failed to stop positioning: ${e.message}');
    }
  }
}
