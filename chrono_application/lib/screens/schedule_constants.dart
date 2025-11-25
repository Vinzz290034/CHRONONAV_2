import 'package:flutter/material.dart';

// --- ENUMS ---
enum ViewMode { day, week, month, year }

// --- COLORS ---
// Replace with your actual color definitions
const Color kPrimaryColor = Color(0xFF0D6335); // Example: Dark Green
const Color kAccentColor = Color(
  0xFFD97706,
); // Example: Orange/Amber for events
const Color kCardBackground = Color(0xFFFFFFFF);
const Color kScaffoldBackground = Color(0xFFF7F7F7);

// --- DIMENSIONS ---
const double kBorderRadius = 12.0;
const double kPadding = 16.0;

// --- UTILITIES ---
// Helper function to convert opacity (0.0 to 1.0) to an Alpha value (0 to 255)
int alphaFromOpacity(double opacity) {
  return (opacity.clamp(0.0, 1.0) * 255).round();
}

// Extension to get a simple name for a ViewMode
extension ViewModeExtension on ViewMode {
  String get name {
    switch (this) {
      case ViewMode.day:
        return 'Day';
      case ViewMode.week:
        return 'Week';
      case ViewMode.month:
        return 'Month';
      case ViewMode.year:
        return 'Year';
    }
  }
}
