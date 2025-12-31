// lib/widgets/navigation_map.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
// ignore: unused_import
import '../models/route_coordinate.dart';

class NavigationMap extends StatelessWidget {
  const NavigationMap({super.key});

  // Default coordinates for the center of your map (matching the mock data: 10, 10)
  static final LatLng initialCenter = LatLng(10.0, 10.0);

  @override
  Widget build(BuildContext context) {
    // 1. Listen to the LocationProvider for state changes
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        // Convert the RouteCoordinate models into the LatLng format required by flutter_map
        final List<LatLng> routePoints = locationProvider.routePath
            .map((coord) => LatLng(coord.lat, coord.lng))
            .toList();

        // Determine the map center and the user's current location marker
        // For initial testing, we center the map on the mock starting point.
        final LatLng currentLocation = routePoints.isNotEmpty
            ? routePoints.first
            : initialCenter;

        return FlutterMap(
          options: MapOptions(
            initialCenter: currentLocation,
            initialZoom: 17.0,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.all &
                  ~InteractiveFlag.rotate, // Prevent rotation
            ),
          ),
          children: [
            // --- A. Base Map Layer ---
            // Using OpenStreetMap tiles for general context.
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.chrononav',
            ),

            // --- B. Route Path Layer (The calculated blue line) ---
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 4.0,
                  color: Colors.blueAccent,
                ),
              ],
            ),

            // --- C. Marker Layer (User and Destination) ---
            MarkerLayer(
              markers: [
                // 1. User Location Marker (Red circle)
                Marker(
                  width: 30.0,
                  height: 30.0,
                  point: currentLocation,
                  child: const Icon(Icons.circle, color: Colors.red, size: 20),
                ),
                // 2. Destination Marker (Green pin - only shows if a route is active)
                if (locationProvider.destinationPoiId != null &&
                    routePoints.isNotEmpty)
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: routePoints.last, // End point of the route
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 35,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
