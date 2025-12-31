// lib/models/route_coordinate.dart

class RouteCoordinate {
  final double lat;
  final double lng;

  RouteCoordinate({required this.lat, required this.lng});

  factory RouteCoordinate.fromJson(Map<String, dynamic> json) {
    // Ensure data coming from the server is treated as double
    return RouteCoordinate(
      lat: json['lat'] as double,
      lng: json['lng'] as double,
    );
  }
}
