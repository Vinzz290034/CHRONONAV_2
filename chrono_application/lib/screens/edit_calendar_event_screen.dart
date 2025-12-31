// edit_calendar_event_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../services/api_service.dart';

class EditCalendarEventScreen extends StatefulWidget {
  final CalendarEvent initialEvent;

  const EditCalendarEventScreen({super.key, required this.initialEvent});

  @override
  State<EditCalendarEventScreen> createState() =>
      _EditCalendarEventScreenState();
}

class _EditCalendarEventScreenState extends State<EditCalendarEventScreen> {
  // --- Controllers ---
  late TextEditingController _eventNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _eventTypeController;

  // --- Date/Time State ---
  late DateTime _startDate;
  DateTime? _endDate; // Correct: Made nullable

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(
      text: widget.initialEvent.eventName,
    );
    // Use null-aware operator for optional fields
    _descriptionController = TextEditingController(
      text: widget.initialEvent.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initialEvent.location ?? '',
    );
    _eventTypeController = TextEditingController(
      text: widget.initialEvent.eventType ?? '',
    );

    _startDate = widget.initialEvent.startDate;
    // Assigns the nullable endDate directly.
    _endDate = widget.initialEvent.endDate;
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _eventTypeController.dispose();
    super.dispose();
  }

  // --- Date/Time Picker Logic ---

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // Use _startDate if _endDate is null for picker initialization
    final currentDateTime = isStartDate ? _startDate : _endDate ?? _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final time = currentDateTime;
      final newDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
      setState(() {
        if (isStartDate) {
          _startDate = newDateTime;
        } else {
          _endDate = newDateTime;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final currentDateTime = isStartTime ? _startDate : _endDate ?? _startDate;
    final initialTime = TimeOfDay.fromDateTime(currentDateTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      final date = currentDateTime;
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        picked.hour,
        picked.minute,
      );
      setState(() {
        if (isStartTime) {
          _startDate = newDateTime;
        } else {
          _endDate = newDateTime;
        }
      });
    }
  }

  // --- API Save Logic ---

  void _saveChanges() async {
    if (!context.mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);

    // 1. Create the updated CalendarEvent model object
    final updatedEventModel = widget.initialEvent.copyWith(
      eventName: _eventNameController.text.trim(),
      // Send null if text field is empty
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      eventType: _eventTypeController.text.trim().isEmpty
          ? null
          : _eventTypeController.text.trim(),
      startDate: _startDate,
      endDate: _endDate, // Pass the nullable state directly
    );

    // Show loading feedback
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving changes...')));

    try {
      // 2. Call the update method (PUT)
      final fullyUpdatedEvent = await apiService.updateCalendarEvent(
        updatedEventModel,
      );

      // 3. Handle success and navigate back
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Event "${fullyUpdatedEvent.eventName}" updated successfully!',
            ),
          ),
        );

        // Pop the screen and pass the fully updated model back to the parent
        Navigator.of(context).pop(fullyUpdatedEvent);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Calendar Event'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editing: ${widget.initialEvent.eventName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),

            // 1. Event Name
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: 'Event Name',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 3. Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Event Type
            TextField(
              controller: _eventTypeController,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),

            // --- Start Date/Time Pickers ---
            const Text(
              'Start Date and Time',
              style: TextStyle(fontWeight: FontWeight.bold, height: 2.0),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectTime(context, true),
                    icon: const Icon(Icons.schedule),
                    label: Text(DateFormat('h:mm a').format(_startDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- End Date/Time Pickers ---
            const Text(
              'End Date and Time',
              style: TextStyle(fontWeight: FontWeight.bold, height: 2.0),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      // Use _startDate if _endDate is null for display purposes
                      DateFormat('yyyy-MM-dd').format(_endDate ?? _startDate),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectTime(context, false),
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      // Use _startDate if _endDate is null for display purposes
                      DateFormat('h:mm a').format(_endDate ?? _startDate),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
