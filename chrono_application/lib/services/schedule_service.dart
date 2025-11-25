// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // We'll assume you have uuid package installed for unique IDs
import '../models/course.dart';

/// Manages the state and logic for the user's academic schedule.
/// It uses ChangeNotifier to notify listeners (UI widgets) of updates.
class ScheduleService with ChangeNotifier {
  // Static map to mock image assets based on course title or code
  static const Map<String, String> _assetMap = {
    'Calculus': 'assets/images/math_class.png',
    'Algorithms': 'assets/images/cs_class.png',
    'Physics': 'assets/images/physics_class.png',
    // Add more mappings as needed
  };

  // Mock initial data, but will be replaced by data added via PDF
  final List<Course> _courses = [
    // Initial mock data removed to show dynamic data addition clearly
  ];

  List<Course> get courses => _courses;

  /// Adds a new course extracted from the PDF to the list.
  void addCourse({
    required String title,
    required String code,
    required String time,
    required String days,
  }) {
    // 1. Generate a unique ID
    const Uuid uuid = Uuid();
    final String id = uuid.v4();

    // 2. Determine a mock image asset path based on keywords in the title
    String asset = 'assets/images/default_class.png';
    String lowerTitle = title.toLowerCase();

    for (var entry in _assetMap.entries) {
      if (lowerTitle.contains(entry.key.toLowerCase())) {
        asset = entry.value;
        break;
      }
    }

    final newCourse = Course(
      id: id,
      title: title,
      code: code,
      time: time,
      days: days,
      imageAsset: asset,
    );

    _courses.add(newCourse);

    // Notify all listening widgets (like DashboardScreen) to rebuild.
    notifyListeners();
  }

  /// Clears all stored courses. (Useful for testing/resetting)
  void clearAllCourses() {
    _courses.clear();
    notifyListeners();
  }

  // NOTE: In a real app, this is where you would handle:
  // - Loading data from Firestore or local storage on startup.
  // - Saving data to Firestore after an update.
}
