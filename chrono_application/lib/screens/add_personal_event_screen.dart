import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart'; // Ensure this path is correct
import '../../models/personal_event.dart'; // Ensure this path is correct

// --- MODERN STYLE CONSTANTS (Define these in your schedule_constants.dart if possible) ---
const Color kPrimaryColor = Color.fromARGB(255, 46, 71, 59); // Dark Green
const Color kAccentColor = Color(0xFFD97706); // Orange/Amber
const double kBorderRadius = 12.0;

// Dark Mode Colors
// ✅ CHANGE: Updated kDarkModeBackground to a darker gray (e.g., #121212)
const Color kDarkModeBackground = Color.fromARGB(
  255,
  18,
  18,
  18,
); // Darker Gray Background
const Color kDarkModeSurface = Color.fromARGB(
  255,
  33,
  33,
  33,
); // Slightly lighter surface for cards/app bars
const Color kDarkModeFieldFill = Color.fromARGB(
  255,
  45,
  45,
  45,
); // Dark field background

// Define the signature for the callback function when an event is successfully created/updated.
typedef EventCreatedCallback = void Function();

class AddPersonalEventScreen extends StatefulWidget {
  final EventCreatedCallback onEventCreated;
  final PersonalEvent? eventToEdit;

  const AddPersonalEventScreen({
    super.key,
    required this.onEventCreated,
    this.eventToEdit,
  });

  @override
  State<AddPersonalEventScreen> createState() => _AddPersonalEventScreenState();
}

class _AddPersonalEventScreenState extends State<AddPersonalEventScreen> {
  // --- Form State ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // --- Date/Time State ---
  late DateTime _startDate;
  late TimeOfDay _startTime;
  DateTime? _endDate;
  // 🐛 FIX: Removed 'late'. Since it's nullable and may not be initialized
  // for a new event in initState, 'late' causes the LateInitializationError
  // when the field is accessed (e.g., inside the button's onPressed).
  TimeOfDay? _endTime;

  // --- Dropdown State ---
  String? _eventType;
  final List<String> _eventTypes = [
    'Meeting',
    'Appointment',
    'Deadline',
    'Study Session',
    'Personal',
    'Other',
  ];

  bool _isSaving = false;
  bool get _isEditing => widget.eventToEdit != null;

  // --- Lifecycle & Disposal ---
  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;

    if (event != null) {
      // Initialize state for EDITING
      _eventNameController.text = event.eventName;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';

      _startDate = event.startDate;
      _startTime = TimeOfDay.fromDateTime(event.startDate);

      _endDate = event.endDate;
      _endTime = event.endDate != null
          ? TimeOfDay.fromDateTime(event.endDate!)
          : null;
    } else {
      // Initialize state for CREATION
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      // NOTE: _endDate and _endTime are correctly null here as they are TimeOfDay? and TimeOfDay? respectively.
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- Date & Time Pickers ---

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final Brightness currentBrightness = Theme.of(context).brightness;
    final bool isDarkMode = currentBrightness == Brightness.dark;

    final DateTime initialDate = isStartDate
        ? _startDate
        : _endDate ?? _startDate;

    final DateTime firstSelectableDate = isStartDate
        ? DateTime(2000)
        : _startDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstSelectableDate,
      lastDate: DateTime(2100),
      // ✨ MODERN DESIGN: Set colors for the DatePicker Theme
      builder: (context, child) {
        return Theme(
          data: isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: kPrimaryColor, // Header background color
                    onPrimary: const Color.fromARGB(
                      255,
                      255,
                      255,
                      255,
                    ), // Header text color
                    surface: const Color.fromARGB(
                      255,
                      44,
                      40,
                      40,
                    ), // Dialog background color
                    onSurface: Colors.white, // Body text color
                  ),
                  // ❌ REMOVED: Removed the problematic dialogTheme override.
                  // Relying on colorScheme.surface for dialog background.
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: kPrimaryColor, // Header background color
                    onPrimary: Colors.white, // Header text color
                    surface: Colors.white, // Dialog background color
                    onSurface: Colors.black, // Body text color
                  ),
                  // ❌ REMOVED: Removed the problematic dialogTheme override.
                  // Relying on colorScheme.surface for dialog background.
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final Brightness currentBrightness = Theme.of(context).brightness;
    final bool isDarkMode = currentBrightness == Brightness.dark;

    final TimeOfDay initialTime = isStartTime
        ? _startTime
        : _endTime ?? TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      // ✨ MODERN DESIGN: Set colors for the TimePicker Theme
      builder: (context, child) {
        return Theme(
          data: isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary:
                        kPrimaryColor, // Clock hand and selected time color
                    onPrimary: Colors.white,
                    surface: const Color.fromARGB(
                      255,
                      44,
                      40,
                      40,
                    ), // Clock face and dialog background
                    onSurface: Colors.white,
                  ),
                  // ❌ REMOVED: Removed the problematic dialogTheme override.
                  // Relying on colorScheme.surface for dialog background.
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary:
                        kPrimaryColor, // Clock hand and selected time color
                    onPrimary: Colors.white,
                    surface: Colors.white, // Clock face and dialog background
                    onSurface: Colors.black,
                  ),
                  // ❌ REMOVED: Removed the problematic dialogTheme override.
                  // Relying on colorScheme.surface for dialog background.
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // --- Form Submission Logic (Unchanged) ---

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving) return;

    final startDateTime = _combineDateTime(_startDate, _startTime);
    final endDateTime = (_endDate != null && _endTime != null)
        ? _combineDateTime(_endDate!, _endTime!)
        : null;

    if (endDateTime != null && endDateTime.isBefore(startDateTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time cannot be before start time.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String startDateIso = startDateTime.toIso8601String();
      final String? endDateIso = endDateTime?.toIso8601String();
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (_isEditing) {
        final eventId = widget.eventToEdit!.id;

        if (eventId == null) {
          throw Exception('Cannot update event: Event ID is missing.');
        }

        final updatedEvent = PersonalEvent(
          id: eventId,
          eventName: _eventNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          startDate: startDateTime,
          endDate: endDateTime,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          eventType: _eventType,
        );

        await apiService.updatePersonalEvent(updatedEvent);
      } else {
        await apiService.createPersonalEvent(
          eventName: _eventNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          startDate: startDateIso,
          endDate: endDateIso,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          eventType: _eventType,
        );
      }

      if (mounted) {
        final successMessage = _isEditing
            ? 'Personal event updated successfully! 🎉'
            : 'Personal event created successfully! ✅';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: kPrimaryColor,
          ),
        );
        widget.onEventCreated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${_isEditing ? 'update' : 'create'} event: ${e.toString()}',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --- Widget Builders ---

  // ✨ MODERN DESIGN: Enhanced InputDecoration for all fields
  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required IconData icon,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color fillColor = isDarkMode
        ? kDarkModeFieldFill
        : Colors.grey.shade50;
    final Color borderColor = isDarkMode
        ? Colors.white38
        : Colors.grey.shade300;
    final Color focusedColor =
        kPrimaryColor; // Primary color remains the focus accent

    // Helper function to safely apply opacity using withAlpha
    // ignore: no_leading_underscores_for_local_identifiers
    Color _applyOpacity(Color color, double opacity) {
      return color.withAlpha((255 * opacity).round());
    }

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      // ⚠️ FIX 2: Replaced kPrimaryColor.withOpacity(0.7) with a safe version
      prefixIcon: Icon(icon, color: _applyOpacity(kPrimaryColor, 0.7)),
      floatingLabelStyle: TextStyle(
        color: focusedColor,
        fontWeight: FontWeight.bold,
      ),
      // ⚠️ FIX 2: Replaced textColor.withOpacity(0.5) with a safe version
      hintStyle: TextStyle(color: _applyOpacity(textColor, 0.5)),
      labelStyle: TextStyle(color: _applyOpacity(textColor, 0.8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius), // Rounded corners
        borderSide: BorderSide.none, // Hide default border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: BorderSide(
          color: focusedColor,
          width: 2,
        ), // Primary color focus highlight
      ),
      filled: true,
      fillColor: fillColor, // Dark/Light background fill
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 10.0,
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime date,
    TimeOfDay time,
    bool isStartDate,
  ) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dateTextColor = isDarkMode ? Colors.white : Colors.black87;

    return Row(
      children: [
        Expanded(
          // Date Picker
          child: InkWell(
            onTap: () => _selectDate(context, isStartDate),
            child: InputDecorator(
              // ✨ Use the enhanced decoration
              decoration: _buildInputDecoration(
                labelText: label,
                icon: Icons.calendar_today_rounded,
              ),
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: dateTextColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // Time Picker
          child: InkWell(
            onTap: () => _selectTime(context, isStartDate),
            child: InputDecorator(
              // ✨ Use the enhanced decoration
              decoration: _buildInputDecoration(
                labelText: 'Time',
                icon: Icons.access_time_rounded,
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: dateTextColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // ✅ Apply kDarkModeBackground (the darker gray) to the Scaffold
    final Color scaffoldColor = isDarkMode ? kDarkModeBackground : Colors.white;
    // Keep the AppBar slightly lighter using kDarkModeSurface
    final Color appBarColor = isDarkMode ? kDarkModeSurface : Colors.white;
    final Color appBarContentColor = isDarkMode ? Colors.white : kPrimaryColor;
    final Color dropdownItemTextColor = isDarkMode
        ? Colors.white
        : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldColor, // Dynamic background
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Personal Event' : 'Add Personal Event',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: appBarContentColor, // Dynamic title color
          ),
        ),
        backgroundColor: appBarColor, // Dynamic AppBar background
        surfaceTintColor: appBarColor, // Dynamic surface tint (for Material 3)
        elevation: 0.5, // Subtle elevation
        iconTheme: IconThemeData(
          color: appBarContentColor,
        ), // Back button color
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Event Name
              TextFormField(
                controller: _eventNameController,
                decoration: _buildInputDecoration(
                  labelText: 'Event Name*',
                  hintText: 'e.g., Project Meeting',
                  icon: Icons.bookmark_rounded,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Event Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _buildInputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Details about the event...',
                  icon: Icons.notes_rounded,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // --- Start Date and Time ---
              _buildDateField(
                context,
                'Start Date/Time*',
                _startDate,
                _startTime,
                true, // isStartDate
              ),
              const SizedBox(height: 20),

              // --- End Date and Time (Optional) ---
              if (_endDate != null) ...[
                _buildDateField(
                  context,
                  'End Date/Time (Optional)',
                  _endDate!,
                  // When _endDate is set, _endTime is guaranteed to be non-null
                  // either by init state or the button logic below, but we use
                  // the null coalescing just in case of an unexpected state.
                  _endTime ?? const TimeOfDay(hour: 23, minute: 59),
                  false, // isStartDate
                ),
                const SizedBox(height: 15),
              ],

              // Add/Remove End Date Button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_endDate == null) {
                      _endDate = _startDate;
                      // When adding the end date, explicitly initialize _endTime
                      // if it's currently null (which it will be for new events).
                      _endTime =
                          _endTime ?? const TimeOfDay(hour: 23, minute: 59);
                    } else {
                      _endDate = null;
                      _endTime = null;
                    }
                  });
                },
                icon: Icon(
                  _endDate == null
                      ? Icons.add_circle_outline
                      : Icons.remove_circle_outline,
                  color: kAccentColor, // Use accent color for this action
                ),
                label: Text(
                  _endDate == null
                      ? 'Add End Date/Time'
                      : 'Remove End Date/Time',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kAccentColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: _buildInputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'e.g., Main Library, Zoom Link',
                  icon: Icons.location_on_rounded,
                ),
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : const Color.fromARGB(255, 44, 40, 40),
                ),
              ),
              const SizedBox(height: 20),

              // Event Type Dropdown
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration(
                  labelText: 'Event Type (Optional)',
                  icon: Icons.category_rounded,
                ),
                value: _eventType,
                hint: Text(
                  'Select Type',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                style: TextStyle(
                  color: dropdownItemTextColor,
                ), // Style for selected item text
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: TextStyle(
                        color: dropdownItemTextColor,
                      ), // Item text color
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _eventType = newValue;
                  });
                },
                dropdownColor: isDarkMode
                    ? kDarkModeFieldFill
                    : Colors.white, // Dropdown background color
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitEvent,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isEditing ? Icons.edit_rounded : Icons.save_rounded,
                        ),
                  label: Text(
                    _isSaving
                        ? 'SAVING...'
                        : (_isEditing ? 'UPDATE EVENT' : 'CREATE EVENT'),
                  ),
                  // ✨ MODERN DESIGN: Large, colored, fully rounded button
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        kBorderRadius * 2,
                      ), // More rounded than fields
                    ),
                    elevation: 5, // A bit of lift
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
