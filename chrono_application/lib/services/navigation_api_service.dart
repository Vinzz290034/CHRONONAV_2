// chrono_application/lib/services/navigation_api_service.dart This service is now ready to be used by your Flutter widgets to request routes and handle the real-time location stream!

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart'; // Import for better logging

// IMPORTANT: Use the IP address of your computer, NOT 'localhost' or '127.0.0.1',
// when running on a physical Android/iOS device.
// If running on an emulator, '10.0.2.2' is often the correct address for the host machine.
const String _baseUrl = 'http://192.168.1.100:3000/api/v1';
const String _wsUrl = 'ws://192.168.1.100:3000';

// Helper function to replace print() with the recommended debugPrint()
void _log(String message) {
  if (kDebugMode) {
    // debugPrint is Flutter's official way to log without causing performance issues
    debugPrint(message);
  }
}

class NavigationApiService {
  // Stores the WebSocket connection
  WebSocketChannel? _channel;

  /// ----------------------------------------------------
  /// 1. HTTP Request for Route Calculation (POST /api/v1/route)
  /// ----------------------------------------------------
  Future<Map<String, dynamic>> getRoute({
    required double startLat,
    required double startLng,
    // FIX 1: Changed destinationPOI_ID to destinationPoiId to follow lowerCamelCase
    required String destinationPoiId,
    required String floorId, // Changed floorID to floorId for consistency
  }) async {
    final uri = Uri.parse('$_baseUrl/route');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'startCoords': {'lat': startLat, 'lng': startLng},
          // Send the correctly formatted key required by the Node.js backend
          'destinationPOI_ID': destinationPoiId,
          'floorID': floorId,
        }),
      );

      if (response.statusCode == 200) {
        // Success!
        return jsonDecode(response.body);
      } else {
        // Error from the backend
        final errorBody = jsonDecode(response.body);
        _log(
          'Failed to get route (${response.statusCode}): ${errorBody['error'] ?? response.reasonPhrase}',
        );
        throw Exception(
          'Routing Error: ${errorBody['error'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      // Network or parsing error
      _log('Network error during routing: $e');
      throw Exception('Network error during routing: $e');
    }
  }

  /// ----------------------------------------------------
  /// 2. WebSocket Connection for Real-Time Data
  /// ----------------------------------------------------

  /// Connects to the WebSocket server for real-time location streaming.
  void connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _log(
        'WebSocket connected successfully.',
      ); // FIX 2: Used _log instead of print
    } catch (e) {
      _log(
        'WebSocket connection error: $e',
      ); // FIX 2: Used _log instead of print
    }
  }

  /// Returns a stream of real-time data from the backend.
  // Note: The analyzer might recommend against nullable streams, but for dynamic WebSocket channels, it's often practical.
  Stream? get locationStream => _channel?.stream;

  /// Sends the current location/sensor data to the backend for processing.
  void sendLocationData(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      _log(
        'WebSocket is not connected. Cannot send data.',
      ); // FIX 2: Used _log instead of print
    }
  }

  /// Closes the WebSocket connection.
  void closeWebSocket() {
    _channel?.sink.close();
    _channel = null;
    _log('WebSocket closed.'); // FIX 2: Used _log instead of print
  }
}
