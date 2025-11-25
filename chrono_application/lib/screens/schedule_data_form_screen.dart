import 'package:flutter/material.dart';
// FIXED PATH: Ensure this path is correct based on your file structure
import '../model/extracted_data_model.dart';
import 'package:intl/intl.dart';

class ScheduleDataFormScreen extends StatefulWidget {
  final ExtractedScheduleData extractedData;

  const ScheduleDataFormScreen({super.key, required this.extractedData});

  @override
  State<ScheduleDataFormScreen> createState() => _ScheduleDataFormScreenState();
}

class _ScheduleDataFormScreenState extends State<ScheduleDataFormScreen> {
  // Global key to manage the form state
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;

  // State for date and time pickers
  late DateTime _selectedDate;
  late TimeOfDay _selectedStartTime;
  late TimeOfDay _selectedEndTime;

  // State for dropdowns
  late String _selectedScheduleType;
  late String _selectedDay;
  late String _selectedFrequency;

  // Static lists for dropdown options
  static const List<String> scheduleTypes = [
    'Lecture',
    'Lab',
    'Seminar',
    'Tutorial',
  ];
  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const List<String> frequencies = [
    'Weekly',
    'Bi-Weekly',
    'Monthly',
    'Once',
  ];

  /// Utility to safely parse a time string (like "10:30 AM") into a TimeOfDay.
  TimeOfDay _parseTime(String timeString) {
    try {
      // Use intl's DateFormat to parse the time string into a DateTime object
      final format = DateFormat.jm(); // Example: 10:30 AM
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      // Fallback to a default time if parsing fails (e.g., 9:00 AM)
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize text controllers
    _codeController = TextEditingController(
      text: widget.extractedData.scheduleCode,
    );
    _titleController = TextEditingController(text: widget.extractedData.title);
    _descController = TextEditingController(
      text: widget.extractedData.description,
    );
    _locationController = TextEditingController(
      text: widget.extractedData.location,
    );

    // Initialize date and time states
    _selectedDate = widget.extractedData.startDate;
    _selectedStartTime = _parseTime(widget.extractedData.startTime);
    // Assuming the new model has an 'endTime', otherwise default to 1 hour later than start time
    // We use a tertiary check to safely access 'endTime' if it exists.
    final endTimeString =
        widget.extractedData.runtimeType.toString().contains('endTime')
        ? (widget.extractedData as dynamic)
              .endTime // Accessing 'endTime' if it exists
        : DateFormat.jm().format(
            _selectedDate.copyWith(
              hour: _selectedStartTime.hour + 1,
              minute: _selectedStartTime.minute,
            ),
          );

    _selectedEndTime = _parseTime(endTimeString);

    // Initialize dropdown state and ensure initial values are valid
    _selectedScheduleType =
        scheduleTypes.contains(widget.extractedData.scheduleType)
        ? widget.extractedData.scheduleType
        : scheduleTypes.first;
    _selectedDay = days.contains(widget.extractedData.dayOfWeek)
        ? widget.extractedData.dayOfWeek
        : days.first;
    _selectedFrequency =
        frequencies.contains(widget.extractedData.repeatFrequency)
        ? widget.extractedData.repeatFrequency
        : frequencies.first;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Date Picker Handler
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.deepPurple, // Body text color
            ),
            // ignore: deprecated_member_use
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Time Picker Handler
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _selectedStartTime : _selectedEndTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.deepPurple.shade900,
            ),
            // ignore: deprecated_member_use
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartTime = picked;
          // Ensure end time is at least 30 mins after start time
          final startDateTime = DateTime(
            2000,
            1,
            1,
            picked.hour,
            picked.minute,
          );
          final minEndDateTime = startDateTime.add(const Duration(minutes: 30));
          final currentEndDateTime = DateTime(
            2000,
            1,
            1,
            _selectedEndTime.hour,
            _selectedEndTime.minute,
          );

          if (currentEndDateTime.isBefore(minEndDateTime)) {
            _selectedEndTime = TimeOfDay.fromDateTime(minEndDateTime);
          }
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }

  // Helper widget to build a form field with consistent styling
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? customValidator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.deepPurple.shade50,
        ),
        maxLines: maxLines,
        validator:
            customValidator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required.';
              }
              return null;
            },
      ),
    );
  }

  // Function to simulate saving the data
  void _saveData() {
    if (_formKey.currentState!.validate()) {
      // Format TimeOfDay back into a standard String format (e.g., "10:30 AM")
      final startTimeString = _selectedStartTime.format(context);
      final endTimeString = _selectedEndTime.format(context);

      // Validation for time order
      final startTime = DateTime(
        2000,
        1,
        1,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );
      final endTime = DateTime(
        2000,
        1,
        1,
        _selectedEndTime.hour,
        _selectedEndTime.minute,
      );

      if (endTime.isBefore(startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error: End Time must be after Start Time.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
        return;
      }

      // Create the final (potentially modified) schedule data object
      final updatedData = ExtractedScheduleData(
        scheduleCode: _codeController.text.trim(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        // Values from dropdowns
        scheduleType: _selectedScheduleType,
        dayOfWeek: _selectedDay,
        repeatFrequency: _selectedFrequency,
        // Values from pickers (now editable)
        startDate: _selectedDate,
        startTime: startTimeString,
        // We assume the model now takes an endTime, otherwise this will cause an error
        // If your model doesn't support 'endTime' yet, you must update the model first.
        endTime: endTimeString,
      );

      // In a real app, you would now save 'updatedData' to a database.
      // For this demo, we'll just show a confirmation message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Schedule Saved! Code: ${updatedData.scheduleCode}, Date: ${DateFormat.yMd().format(updatedData.startDate)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.deepPurple.shade700,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We need the intl package for date formatting.
    final DateFormat formatter = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Review & Edit Schedule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Date and Time (Now Editable) ---
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 25),
                color: Colors.deepPurple.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Timing',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.deepPurple.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(
                        height: 20,
                        thickness: 2,
                        color: Colors.deepPurple,
                      ),
                      _buildDateTile(
                        'Date:',
                        formatter.format(_selectedDate),
                        Icons.calendar_today,
                        () => _selectDate(context),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeTile(
                              'Start Time:',
                              _selectedStartTime.format(context),
                              Icons.access_time,
                              () => _selectTime(context, true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeTile(
                              'End Time:',
                              _selectedEndTime.format(context),
                              Icons.access_time,
                              () => _selectTime(context, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- Editable Fields ---
              _buildTextField(
                _codeController,
                'Schedule Code (e.g., PHYS 101)',
              ),
              _buildTextField(_titleController, 'Title'),

              // Dropdown for Schedule Type
              _buildDropdown(
                label: 'Schedule Type',
                value: _selectedScheduleType,
                items: scheduleTypes,
                onChanged: (newValue) {
                  setState(() {
                    _selectedScheduleType = newValue!;
                  });
                },
              ),

              // Dropdown for Day of Week
              _buildDropdown(
                label: 'Day of Week',
                value: _selectedDay,
                items: days,
                onChanged: (newValue) {
                  setState(() {
                    _selectedDay = newValue!;
                  });
                },
              ),

              // Dropdown for Repeat Frequency
              _buildDropdown(
                label: 'Repeat Frequency',
                value: _selectedFrequency,
                items: frequencies,
                onChanged: (newValue) {
                  setState(() {
                    _selectedFrequency = newValue!;
                  });
                },
              ),

              _buildTextField(_locationController, 'Location', maxLines: 2),
              _buildTextField(
                _descController,
                'Description / Notes',
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveData,
                icon: const Icon(Icons.check_circle_outline, size: 28),
                label: const Text(
                  'Confirm & Save Changes',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.deepPurple.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to display editable date
  Widget _buildDateTile(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple.shade600, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade900,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Icon(Icons.edit, color: Colors.deepPurple, size: 20),
          ],
        ),
      ),
    );
  }

  // Helper widget to display editable time
  Widget _buildTimeTile(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.deepPurple.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the dropdown field
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.deepPurple.shade50,
        ),
        isExpanded: true,
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select an option.';
          }
          return null;
        },
      ),
    );
  }
}
