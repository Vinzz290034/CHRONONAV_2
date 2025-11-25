import 'package:flutter/material.dart';

// 1. Convert to StatefulWidget to manage the state of the switches
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 2. State variables for notification settings
  bool _pushAlertsEnabled = true;
  bool _eventRemindersEnabled = true;
  bool _systemUpdatesEnabled = false;

  // Helper widget for a single notification setting row
  Widget _buildSettingRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          // Switch is now fully functional by calling the provided onChanged
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // 3. Function to handle the "Turn All Off" action
  void _turnAllOff() {
    setState(() {
      _pushAlertsEnabled = false;
      _eventRemindersEnabled = false;
      _systemUpdatesEnabled = false;
    });
    debugPrint('All notifications turned off.');
  }

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).colorScheme.primary,
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
            // --- Upcoming Classes Section ---
            const Text(
              'Upcoming Classes',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 30.0),
              child: Text(
                'No classes loaded. Please add your study load on the Dashboard.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),

            // --- Notification Settings Header ---
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // --- Push Alerts Setting (Uses state and setState) ---
            _buildSettingRow(
              context: context,
              icon: Icons.notifications_none,
              title: 'Push Alerts',
              subtitle:
                  'Receive critical, real-time alerts like room changes or immediate schedule shifts.',
              value: _pushAlertsEnabled,
              onChanged: (bool newValue) {
                setState(() {
                  _pushAlertsEnabled = newValue;
                });
                debugPrint('Push Alerts changed to $newValue');
              },
            ),

            const Divider(),

            // --- Event Reminders Setting (Uses state and setState) ---
            _buildSettingRow(
              context: context,
              icon: Icons.calendar_today,
              title: 'Event Reminders',
              subtitle:
                  'Get reminders for non-class events, deadlines, and club meetings.',
              value: _eventRemindersEnabled,
              onChanged: (bool newValue) {
                setState(() {
                  _eventRemindersEnabled = newValue;
                });
                debugPrint('Event Reminders changed to $newValue');
              },
            ),

            const Divider(),

            // --- System Updates Setting (Uses state and setState) ---
            _buildSettingRow(
              context: context,
              icon: Icons.system_update_alt,
              title: 'System Updates',
              subtitle:
                  'Receive news about new ChronoNav features, maintenance, or version updates.',
              value: _systemUpdatesEnabled,
              onChanged: (bool newValue) {
                setState(() {
                  _systemUpdatesEnabled = newValue;
                });
                debugPrint('System Updates changed to $newValue');
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
