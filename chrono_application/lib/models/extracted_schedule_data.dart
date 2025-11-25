// lib/models/extracted_schedule_data.dart

class ExtractedScheduleData {
  final int id;
  final String eventName;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String eventType;
  final bool isPersonal;

  ExtractedScheduleData({
    required this.id,
    required this.eventName,
    this.description,
    required this.startDate,
    this.endDate,
    this.location,
    required this.eventType,
    required this.isPersonal,
  });

  // 🟢 The missing factory constructor required by ApiService
  factory ExtractedScheduleData.fromJson(Map<String, dynamic> json) {
    return ExtractedScheduleData(
      id: json['id'] as int,
      eventName: json['event_name'] as String,
      description: json['description'] as String?,
      // API returns ISO strings, use DateTime.parse
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      location: json['location'] as String?,
      eventType: json['event_type'] as String,
      // The API returns is_personal as 0 or 1, converting it to a boolean
      isPersonal: json['is_personal'] == 1,
    );
  }
}
