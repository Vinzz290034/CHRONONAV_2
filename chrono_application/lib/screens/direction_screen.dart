import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_entry.dart';
import '../providers/location_provider.dart';
import '../widgets/navigation_map.dart';

// -----------------------------------------------------------------
// 1. Custom QuickNavItem Widget
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
// 2. DirectionScreen
// -----------------------------------------------------------------

class DirectionScreen extends StatefulWidget {
  final List<ScheduleEntry> scheduleEntries;

  const DirectionScreen({super.key, this.scheduleEntries = const []});

  @override
  State<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends State<DirectionScreen> {
  late TextEditingController _searchController;
  List<String> _filteredRooms = [];

  // Scroll Controller for floor buttons
  late ScrollController _floorScrollController;

  int _selectedFloor = 1;

  // Simple stair labels for the second dialog
  final List<String> availableStairs = [
    'Stair 1',
    'Stair 2',
    'Stair 3',
    'Stair 4',
    'Stair 5',
  ];

  List<String> get _uniqueRooms {
    return widget.scheduleEntries
        .where((entry) => entry.room?.isNotEmpty == true)
        .map((entry) => entry.room!)
        .toSet()
        .toList();
  }

  int _getRoomFloor(String room) {
    if (room.isNotEmpty) {
      int? floor = int.tryParse(room[0]);
      return floor ?? 1;
    }
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _floorScrollController = ScrollController(); // Initialize controller
    _searchController = TextEditingController();
    _filteredRooms = _uniqueRooms;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _floorScrollController.dispose(); // Dispose controller
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).clearRoute();
    });

    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredRooms = _uniqueRooms;
      });
      return;
    }

    final filtered = _uniqueRooms.where((room) {
      return room.toLowerCase().contains(query) ||
          widget.scheduleEntries.any((entry) {
            return entry.scheduleCode.toLowerCase().contains(query) ||
                entry.title.toLowerCase().contains(query);
          });
    }).toList();

    setState(() {
      _filteredRooms = filtered;
    });
  }

  void _selectFloor(int floor) {
    setState(() {
      _selectedFloor = floor;
    });

    // Auto-scroll logic to center the selected floor button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_floorScrollController.hasClients) {
        const double buttonWidth = 38.0;
        final double screenWidth = MediaQuery.of(context).size.width;

        final double targetOffset =
            (floor - 1) * buttonWidth - (screenWidth / 2) + (buttonWidth / 2);

        _floorScrollController.animateTo(
          targetOffset.clamp(
            0.0,
            _floorScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.routePath.isEmpty) {
      locationProvider.clearRoute();
    }
  }

  String _getFloorImagePath(int floor) {
    return 'assets/floorplans/floor_$floor.png';
  }

  // UPDATED FUNCTION: Generates unique instructions for 521, 530C, and Restroom
  List<String> _generateInstructions(
    String startPoiId,
    String destination,
    String startFloorId,
    int destinationFloor,
  ) {
    // Determine the room number (e.g., '521' or '530C')
    final destinationPoiId = destination.replaceFirst('Room ', '');
    final startFloor = startFloorId.replaceFirst('level', 'Floor ');
    final destFloor = destinationFloor.toString();

    // Determine floor transition step
    String floorChangeInstruction = startFloor == destFloor
        ? '3. Continue on this floor.'
        : '3. Take the nearest elevator or stairs to Floor $destFloor.';

    List<String> initialSteps;

    // STEP 1: STAIR-SPECIFIC STARTING STEPS
    switch (startPoiId) {
      case 'Stair 1':
        initialSteps = [
          '1. Exit Stair 1 and turn right toward the Computer Lab hallway.',
          '2. Walk past the lab entrance and head toward the North wing.',
          floorChangeInstruction,
        ];
        break;
      case 'Stair 2':
        initialSteps = [
          '1. Exit Stair 2 and proceed West toward the central Elevator core.',
          '2. Head North past the Borrower Services desk.',
          floorChangeInstruction,
        ];
        break;
      case 'Stair 3':
        initialSteps = [
          '1. Exit Stair 3 and turn West onto the main hallway.',
          '2. Follow the corridor as it curves toward the building center.',
          floorChangeInstruction,
        ];
        break;
      case 'Stair 4':
        initialSteps = [
          '1. From Stair 4, exit and head South towards the Faculty wing.',
          '2. Pass the Administrative office and turn right at the first intersection.',
          floorChangeInstruction,
        ];
        break;
      case 'Stair 5':
        initialSteps = [
          '1. Exit the rear stairwell (Stair 5) and walk straight toward the Canteen area.',
          '2. Turn right before the Canteen entrance to locate the main elevators.',
          floorChangeInstruction,
        ];
        break;
      default:
        initialSteps = [
          '1. Exit your current stairwell and locate the main corridor.',
          '2. Head toward the central elevator lobby area.',
          floorChangeInstruction,
        ];
    }

    // STEP 2: ARRIVAL LOGIC FOR RESTROOM, 521, AND 530C
    String finalDestinationStep =
        '4. Your destination, $destination, is nearby.';

    // Custom final steps based on your specific rooms
    if (destination.contains('Cafeteria')) {
      finalDestinationStep =
          '4. Enter the main dining hall; the Cafeteria counter is located directly ahead past the seating area.';
    } else if (destination.contains('Dept. Office')) {
      finalDestinationStep =
          '4. Proceed to the Dean\'s wing; the Department Office is the large glass-door suite at the end of the hall.';
    } else if (destination.contains('Restroom')) {
      finalDestinationStep =
          '4. Locate the hallway near the elevators; the Restroom is situated behind the main lobby area.';
    } else if (destinationPoiId == '530C') {
      finalDestinationStep =
          '4. Turn right at the faculty hallway. Room 530C is at the far end on your left.';
    } else if (destinationPoiId == '521') {
      finalDestinationStep =
          '4. Proceed West past the Dean\'s Office. Room 521 is on the right, across from Lab 525.';
    }
    // Return the combined 4-step instruction list
    return [
      initialSteps[0],
      initialSteps[1],
      initialSteps[2],
      finalDestinationStep,
    ];
  }

  void _startNavigation({
    required String destination,
    required String destinationPoiId,
    required int destinationFloor,
    required String startPoiId,
    required String startFloorId,
  }) {
    final String destinationFloorId = 'level$destinationFloor';

    Provider.of<LocationProvider>(context, listen: false).findAndSetRoute(
      poiId: destinationPoiId,
      startPoiId: startPoiId,
      startFloorID: startFloorId,
      destinationFloorID: destinationFloorId,
    );

    // Switch to the destination floor and trigger the button scroll
    if (_selectedFloor != destinationFloor) {
      _selectFloor(destinationFloor);
    }

    // --- GENERATE UNIQUE INSTRUCTIONS ---
    final List<String> instructionSteps = _generateInstructions(
      startPoiId,
      destination,
      startFloorId,
      destinationFloor,
    );

    // REPLACE SNACKBAR WITH CUSTOM SCROLLABLE DIALOG
    showDialog(
      context: context,
      barrierColor: Colors.black54, // Set barrier color for a dark overlay
      builder: (context) => InstructionOverlayDialog(
        instructions: instructionSteps,
        destination: destination,
        startPoiId: startPoiId,
      ),
    );
  }

  // Second dialog to select the staircase (Stair 1 to 5)
  void _showStairSelectionDialog(
    BuildContext context,
    String destination,
    int destinationFloor,
    int startingFloor,
  ) {
    final rawPoiId = destination.startsWith('Room ')
        ? destination.replaceFirst('Room ', '')
        : destination;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Custom question
          title: const Text('Which stair are you standing now?'),
          // FIX: Corrected MainAxisSize typo
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your staircase on Floor $startingFloor:',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 10),

              // Generate the simple stair list (1-5)
              ...availableStairs
                  .map(
                    (stairName) => ListTile(
                      leading: const Icon(Icons.stairs),
                      title: Text(stairName), // e.g., "Stair 1"
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _startNavigation(
                          destination: destination,
                          destinationPoiId: rawPoiId,
                          destinationFloor: destinationFloor,
                          startPoiId: stairName,
                          startFloorId: 'level$startingFloor',
                        );
                      },
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  // First dialog to select the starting floor (1 to 8)
  void _showStartingFloorSelectionDialog(
    BuildContext context,
    String destination,
    int destinationFloor,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Which floor are you starting from?'),
          // FIX: Wrap the GridView in a SizedBox to provide bounded constraints
          content: SizedBox(
            width: double.maxFinite, // Allow content to expand horizontally
            height:
                250, // Fixed height to prevent intrinsic size calculation error
            // FIX: Corrected MainAxisSize typo
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your destination is Floor $destinationFloor. Select your current floor:',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
                const SizedBox(height: 10),

                // Floor buttons 1 through 8
                Expanded(
                  // Use Expanded since the parent is now sized
                  child: GridView.count(
                    crossAxisCount: 4,
                    // shrinkWrap and NeverScrollableScrollPhysics are okay here
                    // because the GridView is now in a bounded height (SizedBox parent)
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: List.generate(8, (index) {
                      final floor = index + 1;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '$floor',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();

                          // 1. Automatically move floor selector to the chosen STARTING floor
                          _selectFloor(floor);

                          // 2. Show Custom Message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Finally you are now in Floor $floor!',
                              ),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );

                          // 3. DELAY: Pause slightly before showing the next dialog
                          Future.delayed(const Duration(milliseconds: 600), () {
                            // 4. Proceed to ask for the staircase on this STARTING floor
                            _showStairSelectionDialog(
                              context,
                              destination,
                              destinationFloor,
                              floor,
                            );
                          });
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepByStepInstructions(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    if (locationProvider.routePath.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<String> steps = locationProvider.routeSteps;

    if (steps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: Text('Calculating route steps...')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text(
          'Step-by-Step Directions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final step = steps[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(step, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildScheduleRoomsList(BuildContext context) {
    final rooms = _filteredRooms;
    final hintColor = Theme.of(context).hintColor;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (rooms.isEmpty && _searchController.text.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No matching rooms found.',
          style: TextStyle(color: hintColor),
        ),
      );
    }

    if (rooms.isEmpty && _searchController.text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No rooms found in schedule.',
          style: TextStyle(color: hintColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
          'My Schedule Rooms (${rooms.length})',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        // FIXED: Removed unnecessary .toList()
        ...rooms.map((room) {
          final floor = _getRoomFloor(room);
          return ListTile(
            leading: Icon(Icons.meeting_room, color: primaryColor),
            title: Text('Room $room (Floor $floor)'),
            trailing: const Icon(Icons.directions_run),
            // CRITICAL CHANGE: Immediately ask for starting floor
            onTap: () =>
                _showStartingFloorSelectionDialog(context, 'Room $room', floor),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildFloorSelector(BuildContext context, bool isRouteActive) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      controller: _floorScrollController, // ATTACH SCROLL CONTROLLER
      child: Row(
        // Generates 8 buttons (1 to 8)
        children: List.generate(8, (index) {
          final floor = index + 1;
          final isSelected = floor == _selectedFloor;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: isRouteActive ? null : () => _selectFloor(floor),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Text(
                  '$floor',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium!.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRouteActive = Provider.of<LocationProvider>(
      context,
    ).routePath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Direction & Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interactive Campus Map',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            _buildFloorSelector(context, isRouteActive),

            SizedBox(
              height: 250,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 0.8,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: isRouteActive
                      ? const NavigationMap()
                      : Image.asset(
                          _getFloorImagePath(_selectedFloor),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),

            _buildStepByStepInstructions(context),

            const SizedBox(height: 30),

            const Text(
              'Search Destination',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search room or subject...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),

            const SizedBox(height: 10),

            _buildScheduleRoomsList(context),

            const Text(
              'Quick Navigation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.0,
              // FIXED: Removed unnecessary .toList()
              children: [
                QuickNavItem(
                  icon: Icons.restaurant,
                  label: 'Cafeteria',
                  onTap: () => _showStartingFloorSelectionDialog(
                    context,
                    'Cafeteria',
                    1,
                  ),
                ),
                QuickNavItem(
                  icon: Icons.class_,
                  label: 'Your Classes',
                  onTap: () => _showStartingFloorSelectionDialog(
                    context,
                    'Your Next Class',
                    _selectedFloor,
                  ),
                ),
                QuickNavItem(
                  icon: Icons.wc,
                  label: 'Restroom',
                  onTap: () => _showStartingFloorSelectionDialog(
                    context,
                    'Nearest Restroom',
                    _selectedFloor,
                  ),
                ),
                QuickNavItem(
                  icon: Icons.business,
                  label: 'Dept. Office',
                  onTap: () => _showStartingFloorSelectionDialog(
                    context,
                    'Dept. Office',
                    3,
                  ),
                ),
                QuickNavItem(
                  icon: Icons.science,
                  label: 'Lab Room',
                  onTap: () =>
                      _showStartingFloorSelectionDialog(context, 'Lab Room', 4),
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

// -----------------------------------------------------------------
// 3. Custom Instruction Overlay Dialog
// -----------------------------------------------------------------

class InstructionOverlayDialog extends StatelessWidget {
  final List<String> instructions;
  final String destination;
  final String startPoiId;

  const InstructionOverlayDialog({
    super.key,
    required this.instructions,
    required this.destination,
    required this.startPoiId,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic mapping for all Quick Navigation and Room items
    String getNavigationImage() {
      // Extracts only the number from strings like "Stair 5"
      final String number = startPoiId.replaceAll(RegExp(r'[^0-9]'), '');

      // NEW ROOMS LOGIC
      if (destination.contains('530B')) {
        return 'assets/location/530b-$number.png';
      } else if (destination.contains('544')) {
        return 'assets/location/544-$number.png';
      } else if (destination.contains('536')) {
        return 'assets/location/536-$number.png';
      }
      // EXISTING LOGIC
      else if (destination.contains('Lab Room')) {
        return 'assets/location/lab-$number.png';
      } else if (destination.contains('Dept. Office')) {
        return 'assets/location/dean-$number.png';
      } else if (destination.contains('Cafeteria')) {
        return 'assets/location/cafe-$number.png';
      } else if (destination.contains('Restroom')) {
        return 'assets/location/cr-$number.png';
      } else if (destination.contains('530C')) {
        return 'assets/location/530c-$number.png';
      } else {
        // Default fallback for Room 521 and other general stairs
        return 'assets/location/str-$number.png';
      }
    }

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 10,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Navigation Started:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    getNavigationImage(),
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Text("Navigation photo not found")),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(instructions.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          instructions[index],
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.color,
                          ),
                        ),
                      );
                    }),
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
