import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';

// Assuming you have consistent form elements in your project (like input fields)
// For simplicity, we are defining the form structure directly.

class EditCalendarEventScreen extends StatefulWidget {
  final CalendarEvent initialEvent;

  const EditCalendarEventScreen({super.key, required this.initialEvent});

  @override
  State<EditCalendarEventScreen> createState() =>
      _EditCalendarEventScreenState();
}

class _EditCalendarEventScreenState extends State<EditCalendarEventScreen> {
  // Define controllers for the editable fields
  late TextEditingController _eventNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController
  _eventTypeController; // May be a Dropdown/Enum field in final UI

  // Current start/end dates (Using DateTime objects from the model)
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(
      text: widget.initialEvent.eventName,
    );
    _descriptionController = TextEditingController(
      text: widget.initialEvent.description,
    );
    _locationController = TextEditingController(
      text: widget.initialEvent.location,
    );
    _eventTypeController = TextEditingController(
      text: widget.initialEvent.eventType,
    );

    _startDate = widget.initialEvent.startDate;
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

  // --- Form Actions ---

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      // Preserve the time component
      final time = isStartDate ? _startDate : _endDate;
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
    final initialTime = TimeOfDay.fromDateTime(
      isStartTime ? _startDate : _endDate,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      final date = isStartTime ? _startDate : _endDate;
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

  void _saveChanges() {
    // 1. Create the updated CalendarEvent object
    final updatedEvent = widget.initialEvent.copyWith(
      eventName: _eventNameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      eventType: _eventTypeController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      updatedAt: DateTime.now(), // Update timestamp
    );

    // 2. TODOCall API Service to PUT/Update the event (using updatedEvent.toJson())
    // For now, we simulate success and return the updated data.

    // 3. Navigate back and pass the updated event object to refresh the previous screen
    Navigator.of(context).pop(updatedEvent);
  }

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

            // Event Name
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: 'Event Name',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Date/Time Pickers
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
                    label: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectTime(context, false),
                    icon: const Icon(Icons.schedule),
                    label: Text(DateFormat('h:mm a').format(_endDate)),
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
