// lib/models/schedule_entry.dart

// ignore: unused_import
import 'dart:convert';

class ScheduleEntry {
  // Database fields (used for display and API submission)
  final String scheduleCode;
  final String title;
  final String scheduleType;
  final String startDate; // YYYY-MM-DD
  final String startTime; // HH:MM:SS (or HH:MM)
  final String repeatFrequency;

  // Optional fields (Nullable in DB)
  final String? description;
  final String? endDate; // YYYY-MM-DD
  final String? endTime; // HH:MM:SS
  final String? dayOfWeek; // e.g., 'MTWHF'
  // 🎯 UPDATED: Changed field name to 'room'
  final String? room;

  // Metadata (Used internally or by fetch API, NOT by upload API)
  final int? id;
  final int? userId;
  final String? uploaderName;
  final bool? isActive;
  final String? createdAt;

  ScheduleEntry({
    // Required fields based on DB NOT NULL constraint and API validation
    required this.scheduleCode,
    required this.title,
    required this.scheduleType,
    required this.startDate,
    required this.startTime,
    required this.repeatFrequency,

    // Optional fields
    this.description,
    this.endDate,
    this.endTime,
    this.dayOfWeek,
    // 🎯 UPDATED: Changed parameter name to 'room'
    this.room,

    // Metadata (can be null for upload)
    this.id,
    this.userId,
    this.uploaderName,
    this.isActive,
    this.createdAt,
  });

  // Factory constructor for fetching data from the API (GET /api/schedules)
  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      uploaderName: json['uploader_name'] as String?,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: json['created_at'] as String?,

      scheduleCode: json['schedule_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      scheduleType: json['schedule_type'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String?,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String?,
      dayOfWeek: json['day_of_week'] as String?,
      repeatFrequency: json['repeat_frequency'] as String? ?? '',
      // 🎯 UPDATED: Expect 'room' key from the API response
      room: json['room'] as String?,
    );
  }

  // Method for submitting data to the bulk_save API (POST /api/schedules/bulk_save)
  Map<String, dynamic> toJson() {
    return {
      'schedule_code': scheduleCode,
      'title': title,
      'description': description,
      'schedule_type': scheduleType,
      'start_date': startDate,
      'end_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'repeat_frequency': repeatFrequency,
      // 🎯 UPDATED: Send 'room' key in the JSON payload
      'room': room,
      // Note: user_id is NOT included here, as the server adds it from the token.
    };
  }
}
