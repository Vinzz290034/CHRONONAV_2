// --------------------------------------------------------------------------
// Fix in: lib/models/schedule.dart
// --------------------------------------------------------------------------

import 'package:intl/intl.dart'; // You may need to add this import

class Schedule {
  final int? id;
  final String scheduleCode;
  final String title;
  final String? description;
  final String scheduleType;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final String? dayOfWeek;
  final String repeatFrequency;
  final String? location;
  final int userId;
  final int isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Schedule({
    this.id,
    required this.scheduleCode,
    required this.title,
    this.description,
    required this.scheduleType,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.dayOfWeek,
    required this.repeatFrequency,
    this.location,
    required this.userId,
    this.isActive = 1,
    this.createdAt,
    this.updatedAt,
  });

  // Helper for date/time formatting from the database (MySQL)
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  // --- Factory constructor for JSON deserialization (from server) ---
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int?,
      scheduleCode: json['schedule_code'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduleType: json['schedule_type'] as String,
      // Convert date strings to DateTime
      startDate: _dateFormat.parse(json['start_date'] as String),
      endDate: _dateFormat.parse(json['end_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      dayOfWeek: json['day_of_week'] as String?,
      repeatFrequency: json['repeat_frequency'] as String,
      location: json['location'] as String?,
      userId: json['user_id'] as int,
      isActive: json['is_active'] as int? ?? 1,
      // Handle timestamp conversions if needed
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  // --- Method for JSON serialization (to server) ---
  Map<String, dynamic> toJson() {
    return {
      // Omit 'id', 'userId', 'isActive', 'createdAt', 'updatedAt' for POST/PUT if they are server-managed
      'id': id, // Include ID for PUT request
      'schedule_code': scheduleCode,
      'title': title,
      'description': description,
      'schedule_type': scheduleType,
      // Convert DateTime back to required SQL date format string
      'start_date': _dateFormat.format(startDate),
      'end_date': _dateFormat.format(endDate),
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'repeat_frequency': repeatFrequency,
      'location': location,
      'user_id': userId,
      'is_active': isActive,
    };
  }

  // 🎯 THE REQUIRED METHOD TO FIX THE ERROR IN API_SERVICE.dart 🎯
  Schedule copyWith({
    int? id,
    String? scheduleCode,
    String? title,
    String? description,
    String? scheduleType,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? dayOfWeek,
    String? repeatFrequency,
    String? location,
    int? userId,
    int? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      scheduleCode: scheduleCode ?? this.scheduleCode,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduleType: scheduleType ?? this.scheduleType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      location: location ?? this.location,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
