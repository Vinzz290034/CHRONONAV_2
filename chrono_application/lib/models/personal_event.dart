// lib/models/personal_event.dart

class PersonalEvent {
  final int? id;
  final String eventName;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? eventType;

  PersonalEvent({
    this.id,
    required this.eventName,
    this.description,
    required this.startDate,
    this.endDate,
    this.location,
    this.eventType,
  });

  factory PersonalEvent.fromJson(Map<String, dynamic> json) {
    // Helper function for safe Date/Time parsing
    // FIX: Renamed _parseDate to parseDate (removes leading underscore)
    DateTime? parseDate(dynamic dateString) {
      if (dateString == null) return null;
      try {
        // Parse the date string and convert it to the local time zone
        return DateTime.tryParse(dateString.toString())?.toLocal();
      } catch (e) {
        return null;
      }
    }

    // Helper function for safe Int parsing
    // FIX: Renamed _parseInt to parseInt (removes leading underscore)
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // 1. Safely parse all mandatory or nullable fields
    final parsedId = parseInt(json['id']);
    final parsedStartDate = parseDate(json['start_date']);

    // FIX: The variable 'parsedUserId' is now correctly omitted as it was unused.
    // final parsedUserId = parseInt(json['user_id']); // Removed

    // 2. Validate mandatory fields
    if (parsedStartDate == null) {
      throw FormatException(
        'Missing or invalid start date for event: ${json['event_name']}',
      );
    }

    // FIX: Using null-coalescing for eventName to provide a default if null
    final eventName = json['event_name'] as String? ?? 'Unnamed Event';

    // 3. Construct the model
    return PersonalEvent(
      id: parsedId,
      eventName: eventName,
      description: json['description'] as String?,
      startDate: parsedStartDate,
      endDate: parseDate(json['end_date']),
      location: json['location'] as String?,
      eventType: json['event_type'] as String?,
    );
  }

  // Optional: Add toJson method for updating/creating events
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Usually not included for creation
      'event_name': eventName,
      'description': description,
      // Convert DateTime to ISO 8601 string (UTC recommended, but using toIso8601String() for simplicity)
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'event_type': eventType,
      'is_personal': true,
    };
  }
}
