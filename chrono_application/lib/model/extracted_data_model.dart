class ExtractedScheduleData {
  // Core Schedule Details
  final String scheduleCode;
  final String title;
  final String description;
  final String location;

  // Timing Information
  final DateTime startDate;
  final String startTime;
  final String endTime; // <-- Added this field to resolve the error

  // Classification & Frequency
  final String scheduleType;
  final String dayOfWeek;
  final String repeatFrequency;

  const ExtractedScheduleData({
    required this.scheduleCode,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.startTime,
    required this.endTime, // <-- Required in constructor
    required this.scheduleType,
    required this.dayOfWeek,
    required this.repeatFrequency,
  });

  // A simple method for debugging or display
  @override
  String toString() {
    return 'ScheduleData(Code: $scheduleCode, Title: $title, Date: $startDate, Time: $startTime - $endTime, Type: $scheduleType)';
  }

  // Helper method for creating a dummy instance (useful for testing/demo)
  static ExtractedScheduleData dummy() {
    return ExtractedScheduleData(
      scheduleCode: 'CS 201',
      title: 'Introduction to Algorithms',
      description: 'Weekly lecture covering sorting and graph algorithms.',
      location: 'Main Campus, Building A, Room 305',
      startDate: DateTime.now(),
      startTime: '10:00 AM',
      endTime: '11:30 AM', // Dummy end time
      scheduleType: 'Lecture',
      dayOfWeek: 'Monday',
      repeatFrequency: 'Weekly',
    );
  }
}
