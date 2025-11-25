//lib/screens/schedule/date_navigation_bar.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
// Removed unused import: import '../schedule_screen.dart';

class DateNavigationBar extends StatelessWidget {
  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const DateNavigationBar({
    super.key,
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  // Calculate primary text/icon color for visibility
  Color _primaryColor(BuildContext context) {
    // Determine a dark grey/black for light mode, and a near-white for dark mode.
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withOpacity(
            0.9,
          ) // Use withOpacity for simplicity here, though a fixed value like Color(0xE6FFFFFF) is often better.
        : const Color.fromARGB(221, 0, 0, 0); // Near black
  }

  @override
  Widget build(BuildContext context) {
    final color = _primaryColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: color, // Use primary color for icon
              size: 32.0,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color, // Use primary color for text
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: color, // Use primary color for icon
              size: 32.0,
            ),
          ),
        ],
      ),
    );
  }
}
