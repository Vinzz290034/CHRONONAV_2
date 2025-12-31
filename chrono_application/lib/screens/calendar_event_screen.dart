// lib/screens/calendar_event_screen.dart (FINAL CLEANED CODE)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/calendar_event.dart';
import '../services/api_service.dart';

// Helper function to show a detailed view (the "whole post")
void _showEventDetails(BuildContext context, CalendarEvent event) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final Color hintColor = Theme.of(dialogContext).hintColor;

      return AlertDialog(
        title: Text(
          event.eventName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF007A5A),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              // Location and Type
              Text('Location: ${event.location ?? 'N/A'}'),
              Text('Type: ${event.eventType ?? 'General'}'),
              const Divider(height: 15),

              // Date/Time
              Text(
                'Start Time: ${DateFormat('MMM d, yyyy h:mm a').format(event.startDate)}',
              ),
              if (event.endDate != null)
                Text(
                  'End Time: ${DateFormat('MMM d, yyyy h:mm a').format(event.endDate!)}',
                ),
              const SizedBox(height: 10),

              // FULL Description (The "Whole Post" content)
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                event.description ?? 'No detailed description available.',
                style: TextStyle(fontStyle: FontStyle.italic, color: hintColor),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}

class CalendarEventScreen extends StatefulWidget {
  const CalendarEventScreen({super.key});

  @override
  State<CalendarEventScreen> createState() => _CalendarEventScreenState();
}

class _CalendarEventScreenState extends State<CalendarEventScreen> {
  // Use 'late' only for _eventsFuture, initialize others safely
  late Future<List<CalendarEvent>> _eventsFuture;

  // Initialize _currentUserId to 0 (default/non-admin)
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    // Start the async initialization process
    _loadUserIdAndFetchEvents();
  }

  // 🟢 Load user ID and fetch events
  void _loadUserIdAndFetchEvents() async {
    // We use a local context reference in async function
    if (!mounted) return;

    final apiService = Provider.of<ApiService>(context, listen: false);

    // 1. Fetch user ID string
    final userIdString = await apiService.getUserId();

    // 2. Set the state with the fetched ID and start fetching events
    if (mounted) {
      setState(() {
        _currentUserId = int.tryParse(userIdString ?? '0') ?? 0;
        _eventsFuture = _fetchEvents();
      });
    }
  }

  Future<List<CalendarEvent>> _fetchEvents() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final List<CalendarEvent> events = await apiService.fetchCalendarEvents();
      return events;
    } catch (e) {
      throw Exception('Failed to load shared calendar events: $e');
    }
  }

  // 🟢 NEW: Deletion Handler
  Future<void> _deleteEvent(int eventId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.deleteCalendarEvent(eventId);

      // Refresh the list after successful deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Event deleted successfully.')),
        );
        setState(() {
          // Trigger re-fetch
          _eventsFuture = _fetchEvents();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🟢 NEW: Confirmation Dialog
  void _showDeleteConfirmation(int eventId, String eventName) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete the event: "$eventName"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(); // Close dialog
                _deleteEvent(eventId); // Execute delete
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Admin Check: Assume Admin is User ID 1 for now.
    final bool isAdmin = _currentUserId == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Calendar Events'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _eventsFuture = _fetchEvents();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<CalendarEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.none) {
            // Wait until the initial fetch process has started and resolved
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No shared events posted by the administrator yet.'),
            );
          }

          // Data is ready, display the list
          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              // Action buttons for Admins
              final Widget trailingActions = isAdmin
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Delete Button (only available to Admin)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          onPressed: () => _showDeleteConfirmation(
                            event.id,
                            event.eventName,
                          ),
                          tooltip: 'Delete Shared Event',
                        ),
                      ],
                    )
                  : const SizedBox.shrink(); // Regular users see nothing

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(
                    Icons.event_note,
                    color: Color(0xFF007A5A),
                  ),
                  title: Text(
                    event.eventName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location: ${event.location ?? 'N/A'}'),
                      Text('Type: ${event.eventType ?? 'General'}'),
                      Text(
                        'Starts: ${DateFormat('MMM d, h:mm a').format(event.startDate)}',
                      ),
                      if (event.endDate != null)
                        Text(
                          'Ends: ${DateFormat('MMM d, h:mm a').format(event.endDate!)}',
                        ),
                    ],
                  ),
                  // Trailing action buttons
                  trailing: trailingActions,

                  // Tapping the event now shows the full details (the "whole post")
                  onTap: () => _showEventDetails(context, event),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
