// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
// Note: You must ensure these imported files exist and define the classes.
import 'schedule_screen.dart';
import 'direction_screen.dart';
import 'notification_screen.dart';
import 'announcement_screen.dart';
import '../screens/edit_schedule_entry_screen.dart';
import '../models/schedule_entry.dart'; // Import the specific model
import '../services/api_service.dart'; // REQUIRED IMPORT for fetching data
import 'add_pdf_screen.dart';

// --- Placeholder Screens (Unchanged) ---
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

// --- NEW WIDGET: ModernActionButton for Reusable Modern Styling (Unchanged) ---
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

  // 🎯 REQUIRED: Initialize ApiService for fetching data
  final ApiService _apiService = ApiService();

  // --- Search State ---
  late TextEditingController _searchController;
  String _searchQuery = ''; // State to hold the current search text

  // 1. 🚀 STATE: This structure holds the processed schedule data.
  Map<String, dynamic> _scheduleData = const {
    'semester': 'No Schedule Uploaded',
    'total_units': '0',
    'courses': <ScheduleEntry>[], // Store actual ScheduleEntry objects
  };

  bool _isLoading = true; // State to track data loading

  @override
  void initState() {
    super.initState();
    // Initialize search controller
    _searchController = TextEditingController();
    // 🎯 CRITICAL FIX: Load user schedules from the database when the dashboard initializes.
    _loadUserSchedules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Core Data Loading Function (Fetches schedules from DB on login) ---
  Future<void> _loadUserSchedules() async {
    try {
      final List<ScheduleEntry> fetchedEntries = await _apiService
          .fetchUserSchedules()
          .then((list) => list.whereType<ScheduleEntry>().toList());

      // Determine semester/units from fetched data
      if (fetchedEntries.isNotEmpty) {
        final firstEntry = fetchedEntries.first;
        final String startDate = firstEntry.startDate;
        final String semesterName = startDate.isNotEmpty
            ? 'Sem. ${startDate.substring(0, 4)}'
            : 'Unknown Semester';
        final String totalUnits = fetchedEntries.length.toString(); // MOCK

        _scheduleData = {
          'semester': semesterName,
          'total_units': totalUnits,
          'courses': fetchedEntries,
        };
      } else {
        // Explicitly set to empty state if no schedules are found (Fixes Jamil's 148 units issue)
        _scheduleData = const {
          'semester': 'No Schedule Uploaded',
          'total_units': '0',
          'courses': <ScheduleEntry>[],
        };
      }
    } catch (e) {
      debugPrint('Error fetching schedules on startup: $e');
      // Ensure state is reset even on error
      _scheduleData = const {
        'semester': 'No Schedule Uploaded',
        'total_units': '0',
        'courses': <ScheduleEntry>[],
      };
    } finally {
      // Must call setState to stop the loading indicator even if no data was found
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 2. 🚀 UPDATER: Accepts the List<ScheduleEntry> returned from AddPdfScreen/Edit Screen
  void _updateScheduleData(List<ScheduleEntry> entries) {
    String semesterName = 'No Schedule Uploaded';
    String totalUnits = '0';
    List<ScheduleEntry> courses = [];

    if (entries.isNotEmpty) {
      final firstEntry = entries.first;
      final String startDate = firstEntry.startDate;
      semesterName = startDate.isNotEmpty
          ? 'Sem. ${startDate.substring(0, 4)}'
          : 'Unknown Semester';
      totalUnits = entries.length.toString();
      courses = entries;
    }

    setState(() {
      _scheduleData = {
        'semester': semesterName,
        'total_units': totalUnits,
        'courses': courses,
      };
      // Reset search filter after data update
      _searchQuery = '';
      _searchController.clear();
      debugPrint('Schedule Data Updated: $_scheduleData');
    });
  }

  // --- Filtering Logic ---
  List<ScheduleEntry> _getFilteredClasses() {
    final allClasses = _getUpcomingClasses();
    final query = _searchQuery.toLowerCase().trim();

    if (query.isEmpty) {
      return allClasses;
    }

    // Filter classes based on code, title, room, or day
    return allClasses.where((entry) {
      final details =
          '${entry.scheduleCode} ${entry.title} ${entry.room} ${entry.dayOfWeek} ${entry.startDate}';

      return details.toLowerCase().contains(query);
    }).toList();
  }

  // 🚀 HANDLER for when a single entry is edited and saved (from EditScreen)
  void _handleEntryUpdate(ScheduleEntry updatedEntry) {
    final currentCourses = _getUpcomingClasses();

    final index = currentCourses.indexWhere(
      (entry) =>
          entry.id == updatedEntry.id, // Match by ID is safer than scheduleCode
    );

    if (index != -1) {
      final List<ScheduleEntry> newCourses = List.from(currentCourses);
      newCourses[index] = updatedEntry;

      // Update the local state with the list containing the fixed entry
      _updateScheduleData(newCourses);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule updated locally! (API sync pending)'),
        ),
      );
    }
  }

  // 3. ❌ NEW: Delete Handler - Performs API call and updates local state
  Future<void> _deleteScheduleEntry(ScheduleEntry entry) async {
    final scheduleId = entry.id;
    if (scheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Schedule ID is missing.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Call the API service to delete the entry
      await _apiService.deleteScheduleEntry(scheduleId.toString());

      // 2. Update local state by removing the deleted entry
      final currentCourses = _getUpcomingClasses();
      final List<ScheduleEntry> newCourses = currentCourses
          .where((e) => e.id != scheduleId)
          .toList();

      _updateScheduleData(newCourses);

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Schedule ${entry.scheduleCode} deleted successfully!',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      // Show failure message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to delete schedule: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      widget.onProfileTap();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  List<ScheduleEntry> _getUpcomingClasses() {
    return (_scheduleData['courses'] as List?)?.cast<ScheduleEntry>() ?? [];
  }

  // Helper Widget for Upcoming Class Tiles (Modified to accept ScheduleEntry)
  Widget _buildClassTile({
    required BuildContext context,
    required ScheduleEntry data,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final Color cardColor = Theme.of(context).cardColor;

    final String title = '${data.scheduleCode}: ${data.title}';

    final String details =
        '${data.dayOfWeek ?? 'N/A'} | Time: ${data.startTime} | Room: ${data.room ?? 'N/A'} | Starts: ${data.startDate}';

    const String imageAsset = 'assets/images/default_class.png';

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    child: Row(
                      // <-- Row added to contain both buttons
                      children: [
                        // View / Edit Button
                        OutlinedButton(
                          onPressed: () async {
                            final updatedEntry = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditScheduleEntryScreen(entry: data),
                              ),
                            );

                            if (updatedEntry is ScheduleEntry) {
                              _handleEntryUpdate(updatedEntry);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'View / Edit',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),

                        const SizedBox(width: 8), // Spacer
                        // ❌ MODIFIED: Delete Text Button
                        TextButton(
                          onPressed: () => _confirmDeletion(data),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ), // Reduced padding for compactness
                            minimumSize: Size.zero, // Minimal size constraint
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 14),
                            foregroundColor:
                                Colors.red.shade600, // Explicit red color
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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

  // 4. 🗑️ NEW: Confirmation Dialog
  Future<void> _confirmDeletion(ScheduleEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete the schedule for ${entry.scheduleCode}? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteScheduleEntry(entry);
    }
  }

  Widget _buildSummaryCard(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    final String semester = _scheduleData['semester'] ?? 'No Schedule Uploaded';
    final String units = _scheduleData['total_units'] ?? '0';
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

  Widget _buildHomeContent(BuildContext context) {
    final String userName = widget.userData['fullname'] ?? 'User';

    // 3. 🔄 FETCH DATA: Get the filtered list based on search query.
    final List<ScheduleEntry> upcomingClasses = _getFilteredClasses();

    const int alphaFor10Percent = 26;

    // 🎯 FIX: Display CircularProgressIndicator while loading
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- Welcome Header (Unchanged) ---
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

          // --- Search Bar (Functional Input) ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // Update the state with the new query to trigger filtering and rebuild
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search course name, room, or subject...',
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

          // --- Schedule Summary Card (Updated to use new state) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildSummaryCard(context),
          ),

          const SizedBox(height: 30),

          // --- Campus Bulletin Board Section (Unchanged) ---
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

          // --- Add Study Load Section ---
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
                    // 4. 🚀 ACTION: Await the result and check for Map<String, dynamic>
                    SizedBox(
                      height: 40, // Slightly taller for better touch target
                      child: FilledButton(
                        onPressed: () async {
                          debugPrint('Add Study Load clicked - Navigating');

                          // Await the result from AddPdfScreen (Expects List<ScheduleEntry>)
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPdfScreen(),
                            ),
                          );

                          // 🚀 CRITICAL FIX: Check if the result is the expected List<ScheduleEntry>
                          if (result is List<ScheduleEntry>) {
                            // Update the state with the newly extracted list
                            _updateScheduleData(result);
                          } else {
                            debugPrint(
                              'Navigation result was null or wrong type (expected List<ScheduleEntry>): $result',
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
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

          // --- Upcoming Classes Header (Unchanged) ---
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

          // 5. 🔄 DISPLAY: Upcoming Classes List (Uses _getUpcomingClasses)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                if (upcomingClasses.isEmpty && _searchQuery.isEmpty)
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
                else if (upcomingClasses.isEmpty && _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      // ignore: unnecessary_brace_in_string_interps
                      'No classes match your search term: "${_searchQuery}"',
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
                    // Map ScheduleEntry objects to UI Tiles
                    (entry) => _buildClassTile(context: context, data: entry),
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

    // 🎯 Get the schedules list for passing to other screens
    final List<ScheduleEntry> currentSchedules = _getUpcomingClasses();

    // Define and initialize screens here, where context is valid
    final List<Widget> screens = [
      _buildHomeContent(context),
      const ScheduleScreen(),
      // 🎯 FIX: Pass the current list of schedules to the DirectionScreen
      DirectionScreen(scheduleEntries: currentSchedules),
      // 🎯 FIX: Pass the current list of schedules to the NotificationScreen
      NotificationScreen(scheduleEntries: currentSchedules),

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
