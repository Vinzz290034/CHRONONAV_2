import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🎯 NEW: For persistence
import '../models/schedule_entry.dart'; // IMPORTANT: ScheduleEntry model

class NotificationScreen extends StatefulWidget {
  // 🎯 REQUIRED: Accept the list of schedules from the Dashboard
  final List<ScheduleEntry> scheduleEntries;

  const NotificationScreen({super.key, this.scheduleEntries = const []});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 2. State variables for general notification settings (Initial state will be overwritten by storage)
  bool _pushAlertsEnabled = true;
  bool _eventRemindersEnabled = true;
  bool _systemUpdatesEnabled = false;

  // Stores the *user's preference* for each class, independent of master switch
  final Map<String, bool> _classPreferenceStates = {};

  // Tracks the currently selected entry for the detailed view.
  ScheduleEntry? _selectedEntry;

  // Helper getters for theme colors
  Color get _textColor => Theme.of(context).textTheme.bodyMedium!.color!;
  Color get _hintColor => Theme.of(context).hintColor;
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    // 1. Load saved preferences
    _loadPreferences();

    // 2. Initialize class preference states (Defaults to true, will be managed by master switch)
    for (var entry in widget.scheduleEntries) {
      if (entry.scheduleCode.isNotEmpty) {
        // We initialize preferences here, but they are subject to the master switch state
        _classPreferenceStates[entry.scheduleCode] = true;
      }
    }

    // 3. Set the first class as the initially selected detail alert
    if (widget.scheduleEntries.isNotEmpty) {
      _selectedEntry = widget.scheduleEntries.first;
    }
  }

  // 🎯 NEW: Async method to load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load general settings, defaulting to current code defaults if not found
    final bool savedPush = prefs.getBool('pref_push_alerts') ?? true;
    final bool savedEvent = prefs.getBool('pref_event_reminders') ?? true;
    final bool savedSystem = prefs.getBool('pref_system_updates') ?? false;

    setState(() {
      _pushAlertsEnabled = savedPush;
      _eventRemindersEnabled = savedEvent;
      _systemUpdatesEnabled = savedSystem;
    });
    // NOTE: Class-specific preferences would require separate, dedicated storage/loading logic.
  }

  // 🎯 NEW: Method to save preference changes
  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    debugPrint('Preference saved: $key = $value');
  }

  // Moves the tapped entry to the detailed view position
  void _selectEntryForDetail(ScheduleEntry entry) {
    setState(() {
      _selectedEntry = entry;
    });
  }

  // Helper widget for a single notification setting row (General Settings)
  Widget _buildSettingRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String prefsKey, // 🎯 NEW: Key for saving to SharedPreferences
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ignore: deprecated_member_use
          Icon(
            icon,
            size: 28,
            // ignore: deprecated_member_use
            color: enabled ? _primaryColor : _hintColor.withOpacity(0.5),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    // ignore: deprecated_member_use
                    color: enabled ? _textColor : _hintColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    // ignore: deprecated_member_use
                    color: enabled ? _hintColor : _hintColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled
                ? (newValue) {
                    onChanged(newValue);
                    _savePreference(prefsKey, newValue); // 🎯 SAVE HERE
                  }
                : null,
            activeColor: _primaryColor,
            // ignore: deprecated_member_use
            inactiveThumbColor: _hintColor.withOpacity(0.5),
            // ignore: deprecated_member_use
            inactiveTrackColor: _hintColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  // Builds the detailed class alert card
  Widget _buildDetailedAlertCard(ScheduleEntry entry) {
    // 🎯 Use individual preference for switch state, but disable if master is off
    final bool isIndividuallyEnabled =
        _classPreferenceStates[entry.scheduleCode] ?? false;

    final String timeDetail = entry.startTime.isNotEmpty
        ? entry.startTime
        : 'TBA';
    final String dayDetail = entry.dayOfWeek?.isNotEmpty == true
        ? entry.dayOfWeek!
        : 'N/A';
    final String roomDetail = entry.room?.isNotEmpty == true
        ? entry.room!
        : 'N/A';
    final String title = entry.title;
    final String scheduleCode = entry.scheduleCode;

    final bool switchEnabled = _pushAlertsEnabled; // Master switch state

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Alert: $scheduleCode',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _primaryColor,
              ),
            ),
            const Divider(),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: _hintColor),
                const SizedBox(width: 8),
                Text('Time: $timeDetail', style: TextStyle(color: _hintColor)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: _hintColor),
                const SizedBox(width: 8),
                Text('Days: $dayDetail', style: TextStyle(color: _hintColor)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: _hintColor),
                const SizedBox(width: 8),
                Text('Room: $roomDetail', style: TextStyle(color: _hintColor)),
              ],
            ),

            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ignore: deprecated_member_use
                Text(
                  'Enable Notifications',
                  style: TextStyle(
                    color: switchEnabled
                        ? _textColor
                        // ignore: deprecated_member_use
                        : _hintColor.withOpacity(0.7),
                  ),
                ),
                Switch(
                  value: isIndividuallyEnabled,
                  onChanged:
                      switchEnabled // Only allow changing if master switch is ON
                      ? (newValue) {
                          setState(() {
                            _classPreferenceStates[scheduleCode] = newValue;
                          });
                          // TODOAPI call to save alert preference for this course
                        }
                      : null, // Disable the switch if master is off
                  activeColor: _primaryColor,
                  // ignore: deprecated_member_use
                  inactiveThumbColor: _hintColor.withOpacity(0.5),
                  // ignore: deprecated_member_use
                  inactiveTrackColor: _hintColor.withOpacity(0.2),
                ),
              ],
            ),
            if (!switchEnabled) // Show a message if master switch is off
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Push Alerts are globally off. Toggle the main "Push Alerts" switch to enable class notifications.',
                  style: TextStyle(
                    color: _hintColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Builds the list tile for the 'Other Classes' section
  Widget _buildOtherClassTile(ScheduleEntry entry) {
    // 🎯 Use individual preference for switch state, but disable if master is off
    final bool isIndividuallyEnabled =
        _classPreferenceStates[entry.scheduleCode] ?? false;
    final bool switchEnabled = _pushAlertsEnabled; // Master switch state

    final String timeDetail = entry.startTime.isNotEmpty
        ? entry.startTime
        : 'TBA';
    final String roomDetail = entry.room?.isNotEmpty == true
        ? entry.room!
        : 'N/A';
    final String title = entry.title;
    final String scheduleCode = entry.scheduleCode;

    return ListTile(
      leading: Icon(Icons.school, color: _hintColor),
      title: Text(
        '$scheduleCode: $title',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Time: $timeDetail | Room: $roomDetail',
        style: TextStyle(color: _hintColor),
      ),
      trailing: Switch(
        // Use individual preference for the switch's value
        value: isIndividuallyEnabled,
        onChanged:
            switchEnabled // Only allow changing if master switch is ON
            ? (newValue) {
                setState(() {
                  _classPreferenceStates[scheduleCode] = newValue;
                });
                // TODOAPI call to save alert preference for this course
              }
            : null, // Disable the switch if master is off
        activeColor: _primaryColor,
        // ignore: deprecated_member_use
        inactiveThumbColor: _hintColor.withOpacity(0.5),
        // ignore: deprecated_member_use
        inactiveTrackColor: _hintColor.withOpacity(0.2),
      ),
      onTap: () {
        _selectEntryForDetail(entry);
      },
    );
  }

  // 3. Function to handle the "Turn All Off" action
  void _turnAllOff() {
    setState(() {
      _pushAlertsEnabled = false; // Turn off the master switch
      _eventRemindersEnabled = false;
      _systemUpdatesEnabled = false;

      // Class preferences are NOT mass-reset, they are controlled by the master switch being off.
      // We only turn off the master setting here.
      _savePreference('pref_push_alerts', false);
      _savePreference('pref_event_reminders', false);
      _savePreference('pref_system_updates', false);
    });
    debugPrint('All notifications (globally) turned off.');
  }

  @override
  Widget build(BuildContext context) {
    final List<ScheduleEntry> classes = widget.scheduleEntries;

    // Separate the currently selected detail class from the rest
    final List<ScheduleEntry> otherClasses = classes
        .where((entry) => entry.scheduleCode != _selectedEntry?.scheduleCode)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          TextButton(
            // Call the state-updating function
            onPressed: _turnAllOff,
            child: Text(
              'Turn All Off',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Class-Specific Alerts Header ---
            const Text(
              'Class-Specific Alerts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // 🎯 Detail Alert Card (Uses the selected entry)
            if (_selectedEntry != null)
              _buildDetailedAlertCard(_selectedEntry!),

            // --- No Classes/Empty State ---
            if (classes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 30.0),
                child: Text(
                  'No classes loaded. Please add your study load on the Dashboard.',
                  style: TextStyle(fontSize: 14, color: _hintColor),
                ),
              ),

            // --- Other Classes Section ---
            if (otherClasses.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text(
                'Other Classes (${otherClasses.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Build the list of non-selected classes
              ...otherClasses.map((entry) => _buildOtherClassTile(entry)),
            ],

            const SizedBox(height: 30),

            // --- Notification Settings Header (General App Settings) ---
            const Text(
              'General Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // --- Push Alerts Setting (Master Switch) ---
            _buildSettingRow(
              context: context,
              icon: Icons.notifications_none,
              title: 'Push Alerts',
              subtitle:
                  'Receive critical, real-time alerts like room changes or immediate schedule shifts.',
              value: _pushAlertsEnabled,
              prefsKey: 'pref_push_alerts', // 🎯 Prefs Key
              onChanged: (bool newValue) {
                setState(() {
                  _pushAlertsEnabled = newValue;
                  // Individual class preferences are NOT mass-reset/mass-enabled here.
                });
                debugPrint('Push Alerts Master switch changed to $newValue');
                // TODOAdd API call here to save global preference.
              },
            ),

            const Divider(),

            // --- Event Reminders Setting ---
            _buildSettingRow(
              context: context,
              icon: Icons.calendar_today,
              title: 'Event Reminders',
              subtitle:
                  'Get reminders for non-class events, deadlines, and club meetings.',
              value: _eventRemindersEnabled,
              prefsKey: 'pref_event_reminders', // 🎯 Prefs Key
              onChanged: (bool newValue) {
                setState(() {
                  _eventRemindersEnabled = newValue;
                });
                debugPrint('Event Reminders changed to $newValue');
                // TODOAdd API call to save event reminders preference
              },
            ),

            const Divider(),

            // --- System Updates Setting ---
            _buildSettingRow(
              context: context,
              icon: Icons.system_update_alt,
              title: 'System Updates',
              subtitle:
                  'Receive news about new ChronoNav features, maintenance, or version updates.',
              value: _systemUpdatesEnabled,
              prefsKey: 'pref_system_updates', // 🎯 Prefs Key
              onChanged: (bool newValue) {
                setState(() {
                  _systemUpdatesEnabled = newValue;
                });
                debugPrint('System Updates changed to $newValue');
                // TODOAdd API call to save system updates preference
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
