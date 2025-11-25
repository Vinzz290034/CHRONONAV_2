import 'package:flutter/material.dart';

// =========================================================================
// NOTE: For self-contained execution, the Event model and mock data
// are included here, but in a real app, they would reside in 'models/mock_data.dart'.
// If you have your mock_data.dart file, remove this section and uncomment your original import.
// =========================================================================

/// Placeholder Event Model (normally in mock_data.dart)
class Event {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final Color color; // For visual identification

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.color,
  });
}

// Helper for creating time-specific dates relative to 'now'
DateTime _dateAt(int hour, int minute, [int daysOffset = 0]) {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day + daysOffset, // Add offset for future/past days
    hour,
    minute,
  );
}

/// Placeholder Mock Events List (normally in mock_data.dart)
List<Event> mockEvents = [
  // Event for today
  Event(
    id: 'e1',
    title: 'Final Project Submission',
    startTime: _dateAt(10, 0),
    endTime: _dateAt(11, 0),
    location: 'Online Platform',
    color: Colors.red.shade700,
  ),
  Event(
    id: 'e2',
    title: 'Team Meeting with Professor Smith',
    startTime: _dateAt(14, 30),
    endTime: _dateAt(15, 30),
    location: 'Room 301, Engineering Building',
    color: Colors.blue.shade700,
  ),
  // Event for tomorrow
  Event(
    id: 'e3',
    title: 'Study Group - Calculus II',
    startTime: _dateAt(18, 0, 1),
    endTime: _dateAt(20, 0, 1),
    location: 'Library, Study Room B',
    color: Colors.green.shade700,
  ),
  Event(
    id: 'e4',
    title: 'Gym Workout',
    startTime: _dateAt(6, 0, 0),
    endTime: _dateAt(7, 30, 0),
    location: 'Campus Fitness Center',
    color: Colors.orange.shade700,
  ),
];
