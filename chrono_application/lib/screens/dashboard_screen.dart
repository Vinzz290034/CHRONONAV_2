import 'package:flutter/material.dart';
// Note: You must ensure these imported files exist and define the classes.
import 'schedule_screen.dart';
import 'direction_screen.dart';
import 'notification_screen.dart';
import 'announcement_screen.dart';
import 'add_pdf_screen.dart';

// --- Placeholder Screens (Must be defined/imported) ---
class ProfilePlaceholderScreen extends StatelessWidget {
  final VoidCallback onBackToSettings;
  final VoidCallback onClearCachedDataTap;
  final VoidCallback onHelpSupportTap;
  final VoidCallback onLogout;
  final VoidCallback onUpdateUserData;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onDeactivateAccountTap;

  const ProfilePlaceholderScreen({
    required this.onBackToSettings,
    required this.onClearCachedDataTap,
    required this.onHelpSupportTap,
    required this.onLogout,
    required this.onUpdateUserData,
    required this.onChangePasswordTap,
    required this.onDeactivateAccountTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Profile Screen (Placeholder)'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onHelpSupportTap,
          child: const Text('Go to Help & Support'),
        ),
      ],
    ),
  );
}

// --- NEW WIDGET: ModernActionButton for Reusable Modern Styling ---
class ModernActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ModernActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color hintColor = Theme.of(context).hintColor;

    return Card(
      elevation: 4, // Modern subtle elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.zero, // Remove default card margin
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: primaryColor, size: 24),
                  const SizedBox(width: 15),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: hintColor),
            ],
          ),
        ),
      ),
    );
  }
}
// ---------------------------------------------------------------------------------

// --- DashboardScreen Class (Stateful) ---
class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  // Required Callbacks
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onBackToSettings;
  final VoidCallback onClearCachedDataTap;
  final VoidCallback onHelpSupportTap;
  final VoidCallback onLogout;
  final VoidCallback onUpdateUserData;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onDeactivateAccountTap;

  const DashboardScreen({
    required this.userData,
    required this.onSettingsTap,
    required this.onProfileTap,
    required this.onBackToSettings,
    required this.onClearCachedDataTap,
    required this.onHelpSupportTap,
    required this.onLogout,
    required this.onUpdateUserData,
    required this.onChangePasswordTap,
    required this.onDeactivateAccountTap,
    super.key,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // 1. STATE VARIABLE: Holds all extracted data from the PDF upload.
  // The 'courses' key holds the List of classes for display.
  Map<String, dynamic> _extractedScheduleData = const {
    'semester': 'No Schedule Uploaded',
    'total_units': '0',
    'courses': <Map<String, String>>[],
  };

  // 2. STATE UPDATE LOGIC: Updates the state when new data is received.
  void _updateScheduleData(Map<String, dynamic> newScheduleData) {
    setState(() {
      _extractedScheduleData = newScheduleData;
      debugPrint('Schedule Data Updated: $_extractedScheduleData');
    });
  }

  void _onItemTapped(int index) {
    // Check if the tapped index is the "Profile" tab (Index 4)
    if (index == 4) {
      widget.onProfileTap();
    } else {
      // For all other tabs, just switch the screen locally
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Helper Widget for Upcoming Class Tiles
  Widget _buildClassTile({
    required BuildContext context,
    required String title,
    required String details,
    required String imageAsset,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final Color cardColor = Theme.of(context).cardColor;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    details,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 35,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODOImplement navigation to view class details
                        debugPrint('View details for $title clicked');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Image Placeholder for Class Tile
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cardColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).dividerColor,
                      child: Center(
                        child: Icon(
                          Icons.class_sharp,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // NEW WIDGET: Card to display summary data (Semester, Units)
  Widget _buildSummaryCard(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    // Safely access data, defaulting to placeholder values
    final String semester =
        _extractedScheduleData['semester'] ?? 'No Schedule Uploaded';
    final String units = _extractedScheduleData['total_units'] ?? '0';
    final bool hasSchedule = semester != 'No Schedule Uploaded';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              context,
              'Semester',
              semester,
              hasSchedule ? Icons.calendar_today : Icons.cloud_off,
              primaryColor,
            ),
            Container(
              height: 50,
              width: 1,
              color: Theme.of(context).dividerColor,
            ),
            _buildSummaryItem(
              context,
              'Total Units',
              units,
              Icons.book_outlined,
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  // Helper method to build the content for the Home screen (Index 0).
  Widget _buildHomeContent(BuildContext context) {
    final String userName = widget.userData['fullname'] ?? 'User';
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    // Derived list of courses from the extracted schedule data
    // Safely cast the list, defaulting to an empty list if missing or wrong type
    final List<Map<String, String>> upcomingClasses =
        (_extractedScheduleData['courses'] as List?)
            ?.cast<Map<String, String>>() ??
        [];

    // Calculate alpha for 10% opacity (255 * 0.1 = 25.5 -> 26)
    const int alphaFor10Percent = 26;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- Welcome Header ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome, ${userName.split(' ').first}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: widget.onSettingsTap,
                ),
              ],
            ),
          ),

          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).iconTheme.color,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- Schedule Summary Card ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildSummaryCard(context),
          ),

          const SizedBox(height: 30),

          // --- Campus Bulletin Board Section (IMPROVED BUTTON/CARD) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus Bulletin Board',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 15),
                // Use the new ModernActionButton
                ModernActionButton(
                  title: 'View Posts (Announcements)',
                  icon: Icons.announcement_outlined,
                  onTap: () {
                    debugPrint(
                      'View Posts (Announcements) clicked - Navigating',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnnouncementScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- Add Study Load Section (Image Integrated) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).cardColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/study_load_hero.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          // FIXED: Using .withAlpha() instead of deprecated .withOpacity()
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(alphaFor10Percent),
                          child: Center(
                            child: Text(
                              'Image Missing: study_load_hero.png',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Add Study Load',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Plan your academic journey by adding your courses and study hours.',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                    // MODIFIED BUTTON: Navigate and AWAIT result
                    SizedBox(
                      height: 40, // Slightly taller for better touch target
                      child: FilledButton(
                        onPressed: () async {
                          debugPrint('Add Study Load clicked - Navigating');
                          // 3. Await the result from AddPdfScreen
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPdfScreen(),
                            ),
                          );

                          // 4. Check if the result is valid and update the state
                          // NOTE: AddPdfScreen's confirm button must use
                          // Navigator.pop(context, scheduleData) to send data back.
                          if (result is Map<String, dynamic>) {
                            _updateScheduleData(result);
                          } else {
                            debugPrint(
                              'Navigation result was null or wrong type: $result',
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Slightly rounder corners
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ), // Increased padding
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ), // Slightly bolder text
                          elevation: 2, // Subtle lift
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- Upcoming Classes Header ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Upcoming Classes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Upcoming Classes List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                if (upcomingClasses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      'You have no upcoming classes. Upload a schedule PDF to get started!',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  )
                else
                  // Dynamically displays the live schedule items.
                  ...upcomingClasses.map(
                    (cls) => _buildClassTile(
                      context: context,
                      // IMPROVEMENT: Added null-aware access for robustness
                      title: cls['title'] ?? 'Unknown Course',
                      details: cls['details'] ?? 'No details available',
                      // Use a default asset if 'image_asset' is missing
                      imageAsset:
                          cls['image_asset'] ??
                          'assets/images/default_class.png',
                    ),
                  ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    // Define and initialize screens here, where context is valid
    final List<Widget> screens = [
      _buildHomeContent(context),
      const ScheduleScreen(),
      const DirectionScreen(),
      const NotificationScreen(),

      // Index 4: Profile placeholder - Passes all required parameters
      ProfilePlaceholderScreen(
        onBackToSettings: widget.onBackToSettings,
        onClearCachedDataTap: widget.onClearCachedDataTap,
        onHelpSupportTap: widget.onHelpSupportTap,
        onLogout: widget.onLogout,
        onUpdateUserData: widget.onUpdateUserData,
        onChangePasswordTap: widget.onChangePasswordTap,
        onDeactivateAccountTap: widget.onDeactivateAccountTap,
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Theme.of(context).hintColor,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Direction'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notification',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
