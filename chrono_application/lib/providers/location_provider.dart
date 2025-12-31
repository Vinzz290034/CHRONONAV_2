// lib/providers/location_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import '../services/api_service.dart';
import '../models/route_coordinate.dart';

class LocationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- ROUTING STATE VARIABLES ---

  List<RouteCoordinate> _routePath = [];
  List<RouteCoordinate> get routePath => _routePath;

  List<String> _routeSteps = [];
  List<String> get routeSteps => _routeSteps;

  String? _destinationPoiId;
  String? get destinationPoiId => _destinationPoiId;

  bool _isCalculatingRoute = false;
  bool get isCalculatingRoute => _isCalculatingRoute;

  // --- ROUTING METHODS ---

  // UPDATED SIGNATURE: Now uses startPoiId and separate start/destination floor IDs
  Future<void> findAndSetRoute({
    required String poiId,
    required String startPoiId,
    required String startFloorID,
    required String destinationFloorID,
  }) async {
    if (_isCalculatingRoute) return;

    _isCalculatingRoute = true;
    _destinationPoiId = poiId;
    _routePath = [];
    _routeSteps = [];
    notifyListeners();

    try {
      // FIX 1: Corrected API call—only passing new POI/Floor arguments
      final path = await _apiService.calculateRoute(
        startPOI_ID: startPoiId,
        destinationPOI_ID: poiId,
        startFloorID: startFloorID,
        destinationFloorID: destinationFloorID,
      );

      _routePath = path;

      // =======================================================
      // DUMMY STEP POPULATION
      // =======================================================
      final startFloorNumber = startFloorID.replaceFirst('level', 'Floor ');
      final destFloorNumber = destinationFloorID.replaceFirst(
        'level',
        'Floor ',
      );

      _routeSteps = [
        'Starting navigation from $startPoiId on $startFloorNumber.',
        'From the staircase, head straight for 10 meters.',
        'Turn left at the nearest large column.',
        if (startFloorID != destinationFloorID)
          'Proceed to the staircase/elevator you selected to reach $destFloorNumber.',
        if (startFloorID != destinationFloorID)
          'On $destFloorNumber, exit and turn right.',
        'Continue down the main corridor until you see Room $poiId.',
        'Your destination, Room $poiId, is on your left.',
        'You have arrived at $poiId!',
      ];
      // =======================================================

      log(
        'Route calculated successfully: ${path.length} points from $startPoiId.',
        name: 'LocationProvider',
      );
    } catch (e) {
      log('Failed to calculate route: $e', name: 'LocationProvider');
      _routePath = [];
      _routeSteps = [];
    } finally {
      _isCalculatingRoute = false;
      notifyListeners();
    }
  }

  void clearRoute() {
    _routePath = [];
    _routeSteps = [];
    _destinationPoiId = null;
    notifyListeners();
  }
}
