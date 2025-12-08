// lib/screens/view_calendar_event_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart'; // Import the model
import '../services/api_service.dart'; // Import API service for delete/edit logic
import 'edit_calendar_event_screen.dart'; // FIX: Import the dedicated edit screen

// Define colors for consistency (assuming these are defined globally elsewhere)
const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kCalendarEventColor = Color(0xFF9C27B0); // Purple
const double kBorderRadius = 12.0;

class ViewCalendarEventScreen extends StatelessWidget {
  final CalendarEvent event;

  const ViewCalendarEventScreen({super.key, required this.event});

  // Helper to navigate to the dedicated edit screen.
  void _navigateToEdit(BuildContext context) async {
    // FIX: Navigate to the independent EditCalendarEventScreen
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditCalendarEventScreen(
          initialEvent: event, // Pass the CalendarEvent directly
        ),
      ),
    );

    // If EditCalendarEventScreen returns an updated event (or true), signal refresh.
    if (result != null && context.mounted) {
      Navigator.of(context).pop(true); // Signal ScheduleScreen to refresh
    }
  }

  // --- Core Delete Logic ---
  Future<void> _deleteEvent(BuildContext context) async {
    // FIX: Using Provider.of directly inside the try block
    Provider.of<ApiService>(context, listen: false);

    try {
      // NOTE: Call the DELETE API route for calendar events here
      // await apiService.deleteCalendarEvent(event.id.toString());

      // MOCK DELETE (replace with actual API call)
      await Future.delayed(const Duration(milliseconds: 500));

      // Close the view screen and signal success/refresh to the previous screen
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Event "${event.eventName}" deleted.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(true); // Signal refresh
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete event: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // Helper to build detail rows
  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final hintColor = Theme.of(context).hintColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: kCalendarEventColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String timeRange =
        '${DateFormat('h:mm a').format(event.startDate)} - ${DateFormat('h:mm a').format(event.endDate)}';
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: isDarkTheme
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.white,
        elevation: 0.5,
        actions: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit, color: kCalendarEventColor),
            onPressed: () => _navigateToEdit(context),
            tooltip: 'Edit Event',
          ),
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'Delete Event',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Name
            Text(
              event.eventName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kCalendarEventColor,
              ),
            ),
            const SizedBox(height: 4),
            // Event Type
            Text(
              event.eventType ?? 'General Calendar Event',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(height: 30, thickness: 1.0),

            // --- Details Section ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      Icons.calendar_today,
                      'Date',
                      DateFormat('EEEE, MMMM d, yyyy').format(event.startDate),
                    ),
                    _buildDetailRow(
                      context,
                      Icons.access_time_rounded,
                      'Time Range',
                      timeRange,
                    ),
                    _buildDetailRow(
                      context,
                      Icons.location_on_outlined,
                      'Location',
                      event.location ?? 'None specified',
                    ),
                    _buildDetailRow(
                      context,
                      Icons.info_outline,
                      'Created By',
                      'User ID ${event.userId}',
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      Icons.description_outlined,
                      'Description',
                      event.description ?? 'No detailed description available.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Edit/Delete Buttons (Redundant but useful for visibility)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Event Details'),
                onPressed: () => _navigateToEdit(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kCalendarEventColor,
                  side: const BorderSide(color: kCalendarEventColor),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Event'),
                onPressed: () => _showDeleteConfirmation(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Deletion Confirmation Dialog ---
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to permanently delete "${event.eventName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(); // Close the alert
                _deleteEvent(context); // Execute the delete action
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
