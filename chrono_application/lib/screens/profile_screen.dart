import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/profile_avatar.dart';
import 'edit_profile_screen.dart';
import 'feedback_screen.dart';
import 'help_center_screen.dart'; // Import the HelpCenterScreen

class ProfileScreen extends StatefulWidget {
  // Initial data passed from MainAppWrapper
  final Map<String, dynamic> userData;
  final VoidCallback onBackToSettings;

  // Function to send updated user data back to the parent
  final ValueChanged<Map<String, dynamic>> onUpdateUserData;

  // Handlers for security/data actions (required by main.dart)
  final VoidCallback onChangePasswordTap;
  final VoidCallback onDeactivateAccountTap;

  // 🟢 RE-ADDED: This is commonly managed by the AuthWrapper/MainApp.
  final VoidCallback onClearCachedDataTap;

  const ProfileScreen({
    super.key,
    required this.userData,
    required this.onBackToSettings,
    required this.onUpdateUserData,
    required this.onChangePasswordTap,
    required this.onDeactivateAccountTap,
    // 🟢 RE-ADDED: Initialize the new parameter
    required this.onClearCachedDataTap,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Brand Color (ChronoNav green)
  final Color chrononaPrimaryColor = const Color(0xFF007A5A);
  // Define a subtle background color for containers
  final Color _cardBackgroundColor = Colors.white;

  late Map<String, dynamic> _currentUserData;

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.userData;
    _correctProfilePhotoUrl();
  }

  // Handles the correction of the profile photo URL based on the platform.
  void _correctProfilePhotoUrl() {
    String? photoUrl = _currentUserData['photo_url'];

    if (Platform.isAndroid && photoUrl != null && photoUrl.startsWith('http')) {
      if (photoUrl.contains('localhost') || photoUrl.contains('127.0.0.1')) {
        String correctedUrl = photoUrl
            .replaceAll('localhost', '10.0.2.2')
            .replaceAll('127.0.0.1', '10.0.2.2');

        // Update the internal map state
        setState(() {
          _currentUserData = Map.from(_currentUserData);
          _currentUserData['photo_url'] = correctedUrl;
        });
      }
    }
  }

  // Navigate to EditProfileScreen and handle the result
  void _navigateToEditProfile() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfileScreen(initialUserData: _currentUserData),
      ),
    );

    if (updatedData != null && updatedData is Map<String, dynamic>) {
      setState(() {
        _currentUserData = updatedData;
      });
      widget.onUpdateUserData(updatedData);
    }
  }

  // NEW: Navigate to HelpCenterScreen (Internal navigation)
  void _navigateToHelpCenterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
    );
  }

  // Navigate to FeedbackScreen (Internal navigation)
  void _navigateToFeedbackScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
    );
  }

  // --- Helper Widgets for Modern Look ---

  /// A modern Card container to group related items (Profile Details, Security, Support).
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkTheme
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : _cardBackgroundColor;

    return Card(
      color: cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: chrononaPrimaryColor, // Highlight section title
              ),
            ),
            const Divider(height: 20, thickness: 1.0),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Displays a single, non-actionable piece of information within the Card.
  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value, {
    bool showDivider = true,
  }) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor = isDarkTheme ? Colors.white60 : Colors.black54;
    final Color valueColor = isDarkTheme ? Colors.white : Colors.black87;
    final Color dividerColor = Theme.of(context).dividerColor.withAlpha(50);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Divider(height: 0, thickness: 0.5, color: dividerColor),
            ),
        ],
      ),
    );
  }

  /// Builds an actionable item (used for Security & Support sections).
  Widget _buildActionItem(
    BuildContext context, {
    required String title,
    required IconData icon, // New: Leading icon for modern look
    required VoidCallback onTap,
    bool showDivider = true,
    Color? titleColorOverride, // Optional color override for special actions
  }) {
    final Color dividerColor = Theme.of(context).dividerColor.withAlpha(50);
    final Color titleColor =
        titleColorOverride ?? Theme.of(context).textTheme.bodyLarge!.color!;
    final Color iconColor =
        // ignore: deprecated_member_use
        titleColorOverride ?? chrononaPrimaryColor.withOpacity(0.8);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: iconColor, size: 24), // Modern icon
          title: Text(title, style: TextStyle(fontSize: 16, color: titleColor)),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).iconTheme.color!.withAlpha(150),
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(
              left: 40.0,
            ), // Align divider with text
            child: Divider(height: 0, thickness: 0.5, color: dividerColor),
          ),
      ],
    );
  }

  /// Builds the top header with the avatar and greeting.
  Widget _buildHeader(
    BuildContext context,
    String fullName,
    String? profileImagePath,
  ) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final String greetingName = fullName.split(' ')[0];

    return Center(
      child: Column(
        children: [
          ProfileAvatar(photoUrl: profileImagePath, radius: 50),
          const SizedBox(height: 15),
          Text(
            'Hello, $greetingName!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: chrononaPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back to ChronoNavs',
            style: TextStyle(
              fontSize: 16,
              color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fullName =
        _currentUserData['fullname'] ??
        _currentUserData['name'] ??
        'Guest User';
    final String email = _currentUserData['email'] ?? 'N/A';
    final String studentID = _currentUserData['department'] ?? 'N/A';
    final String courseProgram = _currentUserData['course'] ?? 'N/A';
    final String? profileImagePath = _currentUserData['photo_url'];

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkTheme
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50], // Add a subtle light background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: widget.onBackToSettings,
        ),
        title: const Text(
          'Profile Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: chrononaPrimaryColor),
            onPressed: _navigateToEditProfile,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header: User Avatar and Greeting ---
            _buildHeader(context, fullName, profileImagePath),
            const SizedBox(height: 30),

            // --- Profile Details Section ---
            _buildSectionCard(
              context,
              title: 'Profile Details',
              children: [
                _buildInfoItem(context, 'Full Name', fullName),
                _buildInfoItem(context, 'Email', email),
                _buildInfoItem(context, 'Student ID', studentID),
                _buildInfoItem(
                  context,
                  'Course/Program',
                  courseProgram,
                  showDivider: false, // Last item in the card
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Security & Data Section ---
            _buildSectionCard(
              context,
              title: 'Security & Data',
              children: [
                // 1. Change Password
                _buildActionItem(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: widget.onChangePasswordTap,
                ),

                // 🟢 NEW ITEM: Clear Cached Data
                _buildActionItem(
                  context,
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear Cached Data',
                  onTap: widget.onClearCachedDataTap,
                ),

                // 2. Deactivate Account (Highlighted with error color)
                _buildActionItem(
                  context,
                  icon: Icons.person_off_outlined,
                  title: 'Deactivate Account',
                  onTap: widget.onDeactivateAccountTap,
                  titleColorOverride: Theme.of(context).colorScheme.error,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Support Section ---
            _buildSectionCard(
              context,
              title: 'Support',
              children: [
                // 1. Help & Support
                _buildActionItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: _navigateToHelpCenterScreen,
                ),

                // 2. Send Feedback
                _buildActionItem(
                  context,
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  onTap: _navigateToFeedbackScreen,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 50),

            // --- App Version Footer ---
            Center(
              child: Text(
                'ChronoNavs App Version 2.0.0 (Build 42)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkTheme ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
