// lib/providers/schedule_provider.dart

import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';
import '../models/calendar_event.dart';
import '../models/personal_event.dart'; // Assuming you have this model

class ScheduleProvider extends ChangeNotifier {
  // Stores the schedules uploaded by the user
  List<ScheduleEntry> _userSchedules = [];
  // Stores the shared calendar events (Admin posts)
  List<CalendarEvent> _calendarEvents = [];
  // Stores the user's personal events
  List<PersonalEvent> _personalEvents = [];

  bool _isLoading = false;

  // --- Getters ---
  List<ScheduleEntry> get userSchedules => _userSchedules;
  List<CalendarEvent> get calendarEvents => _calendarEvents;
  List<PersonalEvent> get personalEvents => _personalEvents;
  bool get isLoading => _isLoading;

  // 🎯 CRITICAL GETTER: Calculates the count for the notification badge
  int get totalScheduleCount {
    // Count all unique items (classes + shared events + personal events)
    final int classCount = _userSchedules
        .map((e) => e.scheduleCode)
        .toSet()
        .length;
    final int calendarEventCount = _calendarEvents.length;
    final int personalEventCount = _personalEvents.length;

    // This count is currently non-zero if ANY data exists.
    // In a complex app, you might only count 'new' items here.
    return classCount + calendarEventCount + personalEventCount;
  }

  // --- Setter / Fetcher ---

  void updateSchedules({
    List<ScheduleEntry>? userSchedules,
    List<CalendarEvent>? calendarEvents,
    List<PersonalEvent>? personalEvents,
  }) {
    if (userSchedules != null) {
      _userSchedules = userSchedules;
    }
    if (calendarEvents != null) {
      _calendarEvents = calendarEvents;
    }
    if (personalEvents != null) {
      _personalEvents = personalEvents;
    }

    notifyListeners();
  }

  // NOTE: A real app would have fetch methods here that call ApiService
  // and then call updateSchedules upon receiving data.
}
