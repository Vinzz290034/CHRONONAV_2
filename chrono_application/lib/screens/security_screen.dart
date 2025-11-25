// lib/screens/security_screen.dart

import 'package:flutter/material.dart';

class SecurityScreen extends StatefulWidget {
  // Callback to return to the SettingsScreen
  final VoidCallback onBackToSettings;

  const SecurityScreen({required this.onBackToSettings, super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // --- Local State for Security Settings ---
  bool _isMfaEnabled = false;
  bool _isSessionAlertsEnabled = true;

  // --- Helper Widget for setting list tiles ---
  Widget _buildSecurityToggleTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    // Determine dynamic colors
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          // ignore: deprecated_member_use
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Dynamic Colors: The Scaffold and AppBar now pull their colors from the theme.
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        // 🟢 FIX: Removed hardcoded background color: Defaults to Theme's color scheme
        // and uses elevation: 0 by default for modern look.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: widget.onBackToSettings, // Go back to the SettingsScreen
        ),
        title: const Text(
          'Security',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Header Section ---
            Text(
              'Security Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor, // Use primary color for section title
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Control how you secure your account with various options.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 30),

            // --- Multi-Factor Authentication (MFA) ---
            _buildSecurityToggleTile(
              context: context,
              title: 'Multi-Factor Authentication (MFA)',
              subtitle: _isMfaEnabled
                  ? 'MFA is currently ON. A second factor is required for login.'
                  : 'Requires an extra step for login (e.g., SMS code or Authenticator app).',
              value: _isMfaEnabled,
              onChanged: (bool newValue) {
                setState(() {
                  _isMfaEnabled = newValue;
                });
                // 🎯 TODOImplement actual backend call to update MFA status
              },
            ),

            // --- Session Alerts ---
            _buildSecurityToggleTile(
              context: context,
              title: 'New Session Alerts',
              subtitle: _isSessionAlertsEnabled
                  ? 'You will be notified when your account is accessed from a new device.'
                  : 'Alerts are disabled. New logins will not trigger a notification.',
              value: _isSessionAlertsEnabled,
              onChanged: (bool newValue) {
                setState(() {
                  _isSessionAlertsEnabled = newValue;
                });
                // 🎯 TODOImplement actual backend call to update session alerts
              },
            ),

            const SizedBox(height: 30),

            // --- Session Management / Clear History Button ---
            Text(
              'Account Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 15),

            ListTile(
              leading: Icon(Icons.logout, color: primaryColor),
              title: const Text('View and Logout of Other Devices'),
              subtitle: Text(
                'Review recent login activity and end sessions on devices you don\'t recognize.',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 🎯 TODOImplement navigation to Session History Screen
                debugPrint('Navigate to Session History');
              },
              contentPadding: EdgeInsets.zero,
            ),
            // ignore: deprecated_member_use
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),

            // --- Reset Password Link (if not already handled by Change Password screen) ---
            ListTile(
              leading: Icon(Icons.lock_reset, color: primaryColor),
              title: const Text('Reset Security Settings'),
              subtitle: Text(
                'Perform a full security reset on your account (requires email verification).',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 🎯 TODOImplement security reset flow
                debugPrint('Initiate Security Reset');
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
