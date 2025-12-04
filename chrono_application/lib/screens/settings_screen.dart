import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  // --- Required Callbacks & Theme Controls ---
  final VoidCallback onLogout;
  final VoidCallback onBackToDashboard;
  final VoidCallback onSecurityTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onDeactivateAccountTap;
  final VoidCallback onProfileTap;
  final ThemeMode currentThemeMode;
  final void Function(bool) onToggleDarkMode;

  const SettingsScreen({
    required this.onLogout,
    required this.onBackToDashboard,
    required this.onSecurityTap,
    required this.onPrivacyTap,
    required this.onChangePasswordTap,
    required this.onDeactivateAccountTap,
    required this.onProfileTap,
    required this.currentThemeMode,
    required this.onToggleDarkMode,
    super.key,
  });

  // Define brand colors
  final Color chrononaPrimaryColor = const Color(0xFF007A5A);
  final Color chrononaRedColor = const Color(0xFFE53935);

  // --- Helper Widgets ---

  // Refined Section Header (Subtle, slightly muted)
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        30.0, // Increased top padding for spacing between groups
        16.0,
        8.0,
      ),
      child: Text(
        title.toUpperCase(), // All caps for a modern subtitle look
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          // FIX: Replaced withOpacity on ColorScheme member with recommended access
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withAlpha(0x99), // Alpha 0x99 ≈ Opacity 0.6
        ),
      ),
    );
  }

  // Refactored Settings Item for use inside grouped containers
  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailingWidget,
    VoidCallback? onTap,
    Color? titleColor,
    bool showDivider = true,
    Color? iconColor,
  }) {
    // FIX: Removed unused 'isDarkTheme' variable.
    // The usage of Theme.of(context).brightness directly is clean.
    final Color itemIconColor = iconColor ?? chrononaPrimaryColor;
    final Color itemTitleColor =
        titleColor ?? Theme.of(context).textTheme.titleMedium!.color!;

    // FIX: Replaced Theme.of(context).dividerColor.withOpacity(0.5)
    final Color internalDividerColor = Theme.of(
      context,
    ).dividerColor.withAlpha(0x80); // Alpha 0x80 ≈ Opacity 0.5

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          leading: Icon(icon, color: itemIconColor, size: 24),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: itemTitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing:
              trailingWidget ??
              Icon(
                Icons
                    .arrow_forward_ios_rounded, // Use rounded icon for modern feel
                size: 16,
                // FIX: Replaced Colors.grey.withOpacity(0.7)
                color: Colors.grey.withAlpha(0xB3), // Alpha 0xB3 ≈ Opacity 0.7
              ),
          onTap: onTap,
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(
              left: 56.0,
            ), // Indent the divider to align with text
            child: Divider(
              height: 0,
              thickness: 0.5,
              color: internalDividerColor,
            ),
          ),
      ],
    );
  }

  // Helper to wrap items into a modern, rounded container/group
  Widget _buildSettingsGroup({
    required BuildContext context,
    required List<Widget> children,
    required String title,
  }) {
    final Color cardBackgroundColor = Theme.of(context).cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(
                12.0,
              ), // Rounded corners for modern look
              boxShadow: [
                BoxShadow(
                  // FIX: Replaced Colors.black.withOpacity(0.05)
                  color: Colors.black.withAlpha(
                    0x0D,
                  ), // Alpha 0x0D ≈ Opacity 0.05
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Column(children: children), // List of settings items
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Removed unused 'isDarkTheme' variable.
    final Color defaultIconColor = chrononaPrimaryColor;
    final Color defaultTitleColor = Theme.of(
      context,
    ).textTheme.titleMedium!.color!;
    // FIX: Replaced withOpacity
    final Color infoIconColor = Theme.of(
      context,
    ).colorScheme.onSurface.withAlpha(0x80); // Alpha 0x80 ≈ Opacity 0.5

    // Determine if the switch should be ON based on the ThemeMode state
    final bool isDarkMode = currentThemeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: onBackToDashboard,
          color: defaultIconColor,
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Account Section (Grouped) ---
            _buildSettingsGroup(
              context: context,
              title: 'ACCOUNT',
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Profile',
                  onTap: onProfileTap,
                  iconColor: defaultIconColor,
                  titleColor: defaultTitleColor,
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.shield_rounded,
                  title: 'Security',
                  onTap: onSecurityTap,
                  iconColor: defaultIconColor,
                  titleColor: defaultTitleColor,
                  trailingWidget: Icon(
                    Icons.info_outline_rounded,
                    color: infoIconColor,
                    size: 20,
                  ),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.lock_rounded,
                  title: 'Change Password',
                  onTap: onChangePasswordTap,
                  iconColor: defaultIconColor,
                  titleColor: defaultTitleColor,
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.policy_rounded,
                  title: 'Privacy',
                  onTap: onPrivacyTap,
                  iconColor: defaultIconColor,
                  titleColor: defaultTitleColor,
                  trailingWidget: Icon(
                    Icons.info_outline_rounded,
                    color: infoIconColor,
                    size: 20,
                  ),
                  showDivider: false, // Last item in group, no divider
                ),
              ],
            ),

            // --- 2. App Section (Grouped) ---
            _buildSettingsGroup(
              context: context,
              title: 'APP PREFERENCES',
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  iconColor: defaultIconColor,
                  titleColor: defaultTitleColor,
                  trailingWidget: Switch.adaptive(
                    value: isDarkMode,
                    onChanged: onToggleDarkMode,
                    activeColor: chrononaPrimaryColor,
                  ),
                ),
              ],
            ),

            // --- 3. About Section (Grouped) ---
            _buildSettingsGroup(
              context: context,
              title: 'ABOUT',
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.info_rounded,
                  title: 'Version',
                  iconColor: defaultIconColor,
                  titleColor: defaultTitleColor,
                  trailingWidget: Text(
                    '1.0.0',
                    style: TextStyle(
                      // FIX: Replaced withOpacity
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(
                        0x80,
                      ), // Alpha 0x80 ≈ Opacity 0.5
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  showDivider: false,
                  onTap: () => debugPrint('Show Version Info'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 4. Danger Zone (Grouped) ---
            _buildSettingsGroup(
              context: context,
              title: 'DANGER ZONE',
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: 'Deactivate Account',
                  onTap: onDeactivateAccountTap,
                  iconColor: chrononaRedColor,
                  titleColor: chrononaRedColor,
                  showDivider: false,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: chrononaRedColor,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
