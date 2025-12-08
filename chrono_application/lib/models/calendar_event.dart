class CalendarEvent {
  final int id;
  final int userId;
  final String eventName;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final String? eventType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CalendarEvent({
    required this.id,
    required this.userId,
    required this.eventName,
    this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    this.eventType,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor for JSON deserialization

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      eventName: json['event_name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      location: json['location'] as String?,
      eventType: json['event_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for sending to server

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_name': eventName,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location': location,
      'event_type': eventType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields

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
