// lib/models/calendar_event.dart
// ignore: unused_import
import 'package:flutter/material.dart'; // Used for MaterialPageRoute context in some screens

class CalendarEvent {
  final int id;
  final int userId;
  final String eventName;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate; // FIX: Made nullable
  final String? location;
  final String? eventType;
  final DateTime? createdAt; // FIX: Made nullable
  final DateTime? updatedAt; // FIX: Made nullable

  CalendarEvent({
    required this.id,
    required this.userId,
    required this.eventName,
    this.description,
    required this.startDate,
    this.endDate, // FIX: Removed required
    this.location,
    this.eventType,
    this.createdAt, // FIX: Removed required
    this.updatedAt, // FIX: Removed required
  });

  /// Factory constructor for JSON deserialization
  /// FIX: Uses camelCase keys from server's formatCalendarEvent helper.
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int,
      userId: json['userId'] as int,
      eventName: json['eventName'] as String,
      description: json['description'] as String?,
      // NOTE: startDate must be non-null in the DB/Model
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      location: json['location'] as String?,
      eventType: json['eventType'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON for sending to server (POST/PUT payload)
  /// Uses camelCase keys, which the Node.js server maps to snake_case DB columns.
  Map<String, dynamic> toJson() {
    // Only send mutable fields to the server
    return {
      'eventName': eventName,
      'description': description,
      // DateTimes are converted to ISO string format, which the server expects.
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'location': location,
      'eventType': eventType,
      // Note: id, userId, createdAt, updatedAt are handled by the server/URL
    };
  }

  /// FIX: Added copyWith method to resolve "undefined method" error.
  CalendarEvent copyWith({
    int? id,
    int? userId,
    String? eventName,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? eventType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventName: eventName ?? this.eventName,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      eventType: eventType ?? this.eventType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, eventName: $eventName, startDate: $startDate, endDate: $endDate)';
  }
}
