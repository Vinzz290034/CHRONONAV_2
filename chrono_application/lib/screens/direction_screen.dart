import 'package:flutter/material.dart';

// -----------------------------------------------------------------
// 1. Custom QuickNavItem Widget (Stateful for Tap Animation)
// (Kept unchanged from the previous version for visual feedback)
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

  // We only call onTap after the press animation is complete
  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    // Use a small delay to ensure the visual effect registers
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onTap?.call(); // Execute the tap function
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
// 2. DirectionScreen (Updated to include Dialog functionality)
// -----------------------------------------------------------------

class DirectionScreen extends StatelessWidget {
  const DirectionScreen({super.key});

  // New method to show the confirmation dialog
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
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                // IMPORTANT: Replace this with your actual navigation logic
                debugPrint('Navigating to $destination...');
                // Example: Navigator.of(context).push(MaterialPageRoute(builder: (c) => DirectionMapScreen(destination: destination)));
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
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
                      Icons
                          .map_outlined, // Changed to a more map-appropriate icon
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
            TextField(
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

            const SizedBox(height: 30),

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
                  label: 'Restroom', // Changed label for clarity
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
