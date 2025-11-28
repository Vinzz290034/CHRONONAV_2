import 'package:flutter/material.dart';
import '../models/schedule_entry.dart'; // REQUIRED IMPORT

// -----------------------------------------------------------------
// 1. Custom QuickNavItem Widget (Stateful for Tap Animation)
// (Kept unchanged for visual feedback)
// -----------------------------------------------------------------

class QuickNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  State<QuickNavItem> createState() => _QuickNavItemState();
}

class _QuickNavItemState extends State<QuickNavItem> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onTap?.call();
    });
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Theme.of(context).cardColor;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color pressedColor = primaryColor.withAlpha(60);

    final double scale = _isPressed ? 0.95 : 1.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isPressed ? pressedColor : cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 28, color: primaryColor),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// 2. DirectionScreen (Stateful for Search Functionality)
// -----------------------------------------------------------------

class DirectionScreen extends StatefulWidget {
  final List<ScheduleEntry> scheduleEntries;

  const DirectionScreen({super.key, this.scheduleEntries = const []});

  @override
  State<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends State<DirectionScreen> {
  // State for search functionality
  late TextEditingController _searchController;
  List<String> _filteredRooms = [];

  // 🎯 Helper to extract UNIQUE rooms from the schedule list
  List<String> get _uniqueRooms {
    return widget.scheduleEntries
        .where((entry) => entry.room?.isNotEmpty == true)
        .map((entry) => entry.room!)
        .toSet() // Gets only unique rooms
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Initialize filtered list with all unique rooms on startup
    _filteredRooms = _uniqueRooms;

    // Start listening to text changes for dynamic filtering
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- Search Logic ---
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredRooms = _uniqueRooms;
      });
      return;
    }

    // 🎯 Filter the unique room list based on the search query
    final filtered = _uniqueRooms.where((room) {
      // Check if the query matches the room number OR any relevant course code/title
      return room.toLowerCase().contains(query) ||
          widget.scheduleEntries.any((entry) {
            return (entry.scheduleCode.toLowerCase().contains(query) ||
                entry.title.toLowerCase().contains(query));
          });
    }).toList();

    // Since the rooms are unique, we just update the list
    setState(() {
      _filteredRooms = filtered;
    });
  }

  // --- Helper Methods (Dialog, UI Builders) ---

  void _showStartDirectionDialog(BuildContext context, String destination) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Start Directions?'),
          content: Text(
            'Do you want to start navigating to the "$destination" now?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                debugPrint('Navigating to $destination...');
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }

  // 🎯 WIDGET: Builds the list of rooms from the schedule
  Widget _buildScheduleRoomsList(BuildContext context) {
    final rooms = _filteredRooms; // Use the filtered list
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hintColor = Theme.of(context).hintColor;

    if (rooms.isEmpty && _searchController.text.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No schedule rooms match your search query.',
          style: TextStyle(color: hintColor, fontStyle: FontStyle.italic),
        ),
      );
    }

    if (rooms.isEmpty && _searchController.text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No assigned rooms found in your current schedule. Upload a PDF.',
          style: TextStyle(color: hintColor, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
          'My Schedule Rooms (${rooms.length} found)',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // List of unique rooms as tappable tiles
        ...rooms
            .map(
              (room) => ListTile(
                leading: Icon(Icons.meeting_room, color: primaryColor),
                title: Text(
                  'Room $room',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.directions_run, size: 20),
                onTap: () {
                  // Initiate navigation to the specific room
                  _showStartDirectionDialog(context, 'Room $room');
                },
              ),
            )
            // ignore: unnecessary_to_list_in_spreads
            .toList(),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Direction & Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Interactive Campus Map Header ---
            const Text(
              'Interactive Campus Map',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // --- Map View Placeholder ---
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to View Full Campus Map',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- Search Destination Section ---
            const Text(
              'Search Destination',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // 🎯 FIX: Added TextEditingController and onChanged listener
            TextField(
              controller: _searchController,
              onChanged: (_) => _onSearchChanged(),
              decoration: InputDecoration(
                hintText: 'Search course name, room, or subject...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text(
                'Tip: Use the search bar to find specific rooms or professors.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 🎯 REARRANGEMENT FIX: Display My Schedule Rooms List
            // -----------------------------------------------------------------
            _buildScheduleRoomsList(context),

            // --- Quick Navigation Section ---
            const Text(
              'Quick Navigation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Grid View for Navigation Buttons
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.0,
              children: <Widget>[
                QuickNavItem(
                  icon: Icons.local_library,
                  label: 'Library',
                  onTap: () => _showStartDirectionDialog(context, 'Library'),
                ),
                QuickNavItem(
                  icon: Icons.restaurant,
                  label: 'Cafeteria',
                  onTap: () => _showStartDirectionDialog(context, 'Cafeteria'),
                ),
                QuickNavItem(
                  icon: Icons.class_,
                  label: 'Your Classes',
                  onTap: () =>
                      _showStartDirectionDialog(context, 'Your Next Class'),
                ),
                QuickNavItem(
                  icon: Icons.wc,
                  label: 'Restroom',
                  onTap: () =>
                      _showStartDirectionDialog(context, 'Nearest Restroom'),
                ),
                QuickNavItem(
                  icon: Icons.business,
                  label: 'Dept. Office',
                  onTap: () =>
                      _showStartDirectionDialog(context, 'Department Office'),
                ),
                QuickNavItem(
                  icon: Icons.science,
                  label: 'Lab Room',
                  onTap: () =>
                      _showStartDirectionDialog(context, 'Science Lab'),
                ),
              ],
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
