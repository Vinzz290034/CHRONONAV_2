// lib/screens/privacy_screen.dart

import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  // Callback to return to the SettingsScreen
  final VoidCallback onBackToSettings;

  const PrivacyScreen({required this.onBackToSettings, super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  // --- Local State for Privacy Settings ---
  bool _allowPersonalizedAds = true;
  bool _shareUsageData = false;
  bool _enableLocationTracking = false;

  // --- Helper Widget for Toggle list tiles ---
  Widget _buildPrivacyToggleTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
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
    );
  }

  // --- Helper Widget for standard action list tiles (Legal/Account) ---
  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        // 🟢 FIX: AppBar automatically adapts to theme colors
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: widget.onBackToSettings, // Go back to the SettingsScreen
        ),
        title: const Text(
          'Privacy',
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
              'Privacy Controls',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage how your personal information and activity data are used.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 30),

            // --- 📊 Data Usage Section ---
            Text(
              'Data Usage Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 15),

            // Personalized Ads Toggle
            _buildPrivacyToggleTile(
              context: context,
              title: 'Personalized Ads',
              subtitle: _allowPersonalizedAds
                  ? 'We use your preferences to show relevant ads.'
                  : 'Ads will be generic and less relevant to your interests.',
              value: _allowPersonalizedAds,
              onChanged: (bool newValue) {
                setState(() {
                  _allowPersonalizedAds = newValue;
                });
                // 🎯 TODOAPI call to update preference
              },
            ),

            // Share Usage Data Toggle
            _buildPrivacyToggleTile(
              context: context,
              title: 'Share Usage Data for Improvements',
              subtitle: _shareUsageData
                  ? 'Allows anonymous data sharing to help improve app features.'
                  : 'Stops sharing usage and diagnostics data.',
              value: _shareUsageData,
              onChanged: (bool newValue) {
                setState(() {
                  _shareUsageData = newValue;
                });
                // 🎯 TODOAPI call to update preference
              },
            ),

            // Location Tracking Toggle (If applicable for Direction/Map feature)
            _buildPrivacyToggleTile(
              context: context,
              title: 'Location Tracking',
              subtitle: _enableLocationTracking
                  ? 'App may access your location for map and direction features.'
                  : 'Location access is disabled. Some map features may be limited.',
              value: _enableLocationTracking,
              onChanged: (bool newValue) {
                setState(() {
                  _enableLocationTracking = newValue;
                });
                // 🎯 TODOHandle OS permission request/change here
              },
            ),

            const SizedBox(height: 40),

            // --- 📜 Legal & Account Section ---
            Text(
              'Account and Legal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 15),

            // Privacy Policy Link
            _buildActionTile(
              context: context,
              icon: Icons.policy,
              title: 'View Privacy Policy',
              onTap: () {
                debugPrint('Navigate to Privacy Policy web view');
                // 🎯 TODOImplement navigation to web view for Privacy Policy
              },
            ),
            // ignore: deprecated_member_use
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),

            // Terms of Service Link
            _buildActionTile(
              context: context,
              icon: Icons.gavel,
              title: 'View Terms of Service',
              onTap: () {
                debugPrint('Navigate to Terms of Service web view');
                // 🎯 TODOImplement navigation to web view for Terms of Service
              },
            ),
            // ignore: deprecated_member_use
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),

            // Delete Account Option
            _buildActionTile(
              context: context,
              icon: Icons.delete_forever,
              title: 'Delete My Account',
              onTap: () {
                // 🎯 TODOImplement delete account confirmation dialog/flow
                debugPrint('Open Delete Account dialog');
              },
            ),
            // ignore: deprecated_member_use
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
