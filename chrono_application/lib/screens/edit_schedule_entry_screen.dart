import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';
import '../services/api_service.dart'; // REQUIRED IMPORT

class EditScheduleEntryScreen extends StatefulWidget {
  final ScheduleEntry entry;

  const EditScheduleEntryScreen({super.key, required this.entry});

  @override
  State<EditScheduleEntryScreen> createState() =>
      _EditScheduleEntryScreenState();
}

class _EditScheduleEntryScreenState extends State<EditScheduleEntryScreen> {
  // Use TextEditingControllers for mutable fields, pre-filled with current data
  late TextEditingController _titleController;
  late TextEditingController _roomController;
  late TextEditingController _daysController;
  late TextEditingController _startTimeController;
  late TextEditingController
  _startDateController; // For display/editing the date string
  late String _scheduleType;
  late String _repeatFrequency;

  // 🎯 REQUIRED: Initialize ApiService
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the data from the immutable ScheduleEntry
    _titleController = TextEditingController(text: widget.entry.title);
    _roomController = TextEditingController(text: widget.entry.room ?? '');
    _daysController = TextEditingController(text: widget.entry.dayOfWeek ?? '');
    _startTimeController = TextEditingController(text: widget.entry.startTime);
    _startDateController = TextEditingController(text: widget.entry.startDate);

    // Defaulting date if it's an empty string (to prevent UI errors)
    if (_startDateController.text.isEmpty) {
      _startDateController.text = DateTime.now().toString().split(' ')[0];
    }

    _scheduleType = widget.entry.scheduleType;
    _repeatFrequency = widget.entry.repeatFrequency;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _roomController.dispose();
    _daysController.dispose();
    _startTimeController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  // --- Core Functionality ---

  // 🎯 UPDATED: Contains the CRITICAL MOCK ID FIX for demonstration
  void _saveChanges() async {
    // --- TEMPORARY CRITICAL FIX FOR 404 ---
    // ⚠️ CRITICAL: Set this to the LOWEST ID of the schedules INSERTED into your MySQL 'add_pdf' table.
    // (Assuming 141 based on your provided database screenshot)
    const int startDbId = 141;

    int? actualDbId = widget.entry.id;

    // If the ID is the small, mock ID (e.g., 1 or 2, which are < 100), assign a real ID.
    if (widget.entry.id != null && widget.entry.id! < 100) {
      // If the mock ID is 1, actual ID = 141. If mock ID is 2, actual ID = 142.
      actualDbId = startDbId + (widget.entry.id! - 1);
      debugPrint(
        'MOCK FIX APPLIED: Mapped mock ID ${widget.entry.id} to actual DB ID $actualDbId',
      );
    }
    // ----------------------------------------

    final updatedEntry = ScheduleEntry(
      // Required fields updated from controllers/state
      scheduleCode: widget.entry.scheduleCode,
      title: _titleController.text.trim(),
      scheduleType: _scheduleType,
      startDate: _startDateController.text.trim(),
      startTime: _startTimeController.text.trim(),
      repeatFrequency: _repeatFrequency,

      // Optional fields updated
      room: _roomController.text.trim().isNotEmpty
          ? _roomController.text.trim()
          : null,
      dayOfWeek: _daysController.text.trim().isNotEmpty
          ? _daysController.text.trim()
          : null,

      // Preserve original metadata
      id: actualDbId, // 🎯 CRITICAL FIX: Use the actualDbId
      userId: widget.entry.userId,
      uploaderName: widget.entry.uploaderName,
      isActive: widget.entry.isActive,
      createdAt: widget.entry.createdAt,

      // Keep original non-edited fields
      endDate: widget.entry.endDate,
      endTime: widget.entry.endTime,
      description: widget.entry.description,
    );

    try {
      // 1. Send the updated entry to the server (PUT /api/schedules/update/ID)
      await _apiService.updateScheduleEntry(updatedEntry);

      // 2. Notify the user of success
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Schedule updated successfully!')),
      );

      // 3. Return the fully updated entry to the Dashboard
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(updatedEntry);
    } catch (e) {
      // Show failure message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error updating schedule: ${e.toString()}')),
      );
    }
  }

  // -------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Schedule: ${widget.entry.scheduleCode}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Highlight the core problem (e.g., Room: N/A)
            if (widget.entry.room == null || widget.entry.room!.isEmpty)
              Card(
                color: Colors.orange.shade100,
                child: const ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text(
                    'Missing critical data (Room/Location). Please verify.',
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Text Field: Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Course Title'),
            ),
            const SizedBox(height: 16),

            // Text Field: Room (The fix area)
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room/Location (e.g., 540, Auditorium)',
              ),
            ),
            const SizedBox(height: 16),

            // Text Field: Start Date
            TextField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'Start Date (YYYY-MM-DD)',
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),

            // Text Field: Days (M, T, W, H, F, S)
            TextField(
              controller: _daysController,
              decoration: const InputDecoration(
                labelText: 'Days of Week (e.g., MWF, TTH)',
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown: Schedule Type
            DropdownButtonFormField<String>(
              value: _scheduleType,
              decoration: const InputDecoration(labelText: 'Schedule Type'),
              items: const ['class', 'meeting', 'event', 'holiday']
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _scheduleType = newValue;
                  });
                }
              },
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes & Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
