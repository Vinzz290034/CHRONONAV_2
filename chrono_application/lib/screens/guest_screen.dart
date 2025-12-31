import 'package:flutter/material.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  // --- FULL DATASET: GROUND TO 7TH FLOOR ---
  final List<Map<String, dynamic>> allLocations = [
    // Ground Floor
    {
      'label': 'Room 102',
      'cat': 'Academic Rooms',
      'floor': 1,
      'desc': 'General classroom, upper-left wing.',
    },
    {
      'label': 'Accounting',
      'cat': 'Administrative Offices',
      'floor': 1,
      'desc': 'Main financial office, left side.',
    },
    {
      'label': 'Canteen',
      'cat': 'Service & Facilities',
      'floor': 1,
      'desc': 'Dining area near Gate 2.',
    },

    // Mezzanine
    {
      'label': 'Chorus Hall',
      'cat': 'Service & Facilities',
      'floor': 1.5,
      'desc': 'Left wing, below Graduate Office.',
    },
    {
      'label': 'University Chapel',
      'cat': 'Service & Facilities',
      'floor': 1.5,
      'desc': 'Large facility, bottom center.',
    },

    // 2nd Floor
    {
      'label': 'Main Library (2/F)',
      'cat': 'Service & Facilities',
      'floor': 2,
      'desc': 'Top-center area.',
    },
    {
      'label': 'President’s Office',
      'cat': 'Offices',
      'floor': 2,
      'desc': 'Executive suite, center-right.',
    },

    // 3rd Floor
    {
      'label': 'Forensic Science Lab (333)',
      'cat': 'Academic Rooms',
      'floor': 3,
      'desc': 'Far top-left corner.',
    },
    {
      'label': 'Criminology Dean\'s Office',
      'cat': 'Offices',
      'floor': 3,
      'desc': 'Upper-left wing area.',
    },

    // 4th Floor
    {
      'label': 'SMART Wireless Lab (401)',
      'cat': 'Academic Rooms',
      'floor': 4,
      'desc': 'Top-left corridor.',
    },
    {
      'label': 'Speech Lab',
      'cat': 'Academic Rooms',
      'floor': 4,
      'desc': 'Top-right corner.',
    },

    // 5th Floor
    {
      'label': 'Room 521',
      'cat': 'Academic Rooms',
      'floor': 5,
      'desc': 'Across from Computer Lab 525.',
    },
    {
      'label': 'Computer Lab 524',
      'cat': 'Laboratories',
      'floor': 5,
      'desc': 'Left wing technical corridor.',
    },

    // 6th Floor
    {
      'label': 'UC Restaurant',
      'cat': 'Specialized Labs',
      'floor': 6,
      'desc': 'Hospitality hub, top corridor.',
    },
    {
      'label': 'UC Bar',
      'cat': 'Specialized Labs',
      'floor': 6,
      'desc': 'Hospitality hub, top corridor.',
    },

    // 7th Floor
    {
      'label': 'HRM Mini Hotel',
      'cat': 'Specialized Facilities',
      'floor': 7,
      'desc': 'Upper-left wing.',
    },
    {
      'label': 'Criminology Gym',
      'cat': 'Specialized Facilities',
      'floor': 7,
      'desc': 'Large gym, right side.',
    },
  ];

  List<Map<String, dynamic>> _filteredLocations = [];
  final List<String> categories = [
    'All',
    'Academic Rooms',
    'Offices',
    'Service & Facilities',
    'Laboratories',
    'Specialized Labs',
    'Specialized Facilities',
  ];

  @override
  void initState() {
    super.initState();
    _filteredLocations = allLocations;
  }

  void _runFilter(String query) {
    setState(() {
      _filteredLocations = allLocations.where((loc) {
        final matchesName = loc['label'].toLowerCase().contains(
          query.toLowerCase(),
        );
        final matchesCat =
            _selectedCategory == 'All' || loc['cat'] == _selectedCategory;
        return matchesName && matchesCat;
      }).toList();
    });
  }

  void _showStairSelection(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Navigation: ${location['label']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Floor: ${location['floor']}'),
            const SizedBox(height: 10),
            const Text('Which stair are you standing near?'),
            ...List.generate(5, (index) {
              final stair = 'Stair ${index + 1}';
              return ListTile(
                leading: const Icon(Icons.stairs),
                title: Text(stair),
                onTap: () {
                  Navigator.pop(context);
                  _launchNavigation(location, stair);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _launchNavigation(Map<String, dynamic> loc, String stair) {
    List<String> steps = [
      '1. Start at $stair and head to the corridor.',
      '2. Move toward the central core area.',
      '3. Proceed to Floor ${loc['floor']}.',
      '4. Final Arrival: ${loc['desc']}',
    ];

    showDialog(
      context: context,
      builder: (context) => InstructionOverlayDialog(
        instructions: steps,
        destination: loc['label'],
        startPoiId: stair,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Quest')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                hintText: 'Search room or facility...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (val) {
                          setState(() {
                            _selectedCategory = cat;
                            _runFilter(_searchController.text);
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final loc = _filteredLocations[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      loc['label'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(loc['desc']),
                    trailing: const Icon(Icons.directions),
                    onTap: () => _showStairSelection(loc),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
    String getNavigationImage() {
      final String numberStr = startPoiId.replaceAll(RegExp(r'[^0-9]'), '');
      final int stairNum = int.tryParse(numberStr) ?? 1;

      // --- ASSET MAPPING LOGIC ---
      // Ground Floor: grd-1.jpg
      if (destination.contains('102') ||
          destination.contains('Accounting') ||
          destination.contains('Canteen')) {
        return 'assets/floors/ground_floor/grd-$stairNum.jpg';
      }
      // Mezzanine: mez-1.png
      if (destination.contains('Chorus') || destination.contains('Chapel')) {
        return 'assets/floors/mezzanine_floor/mez-$stairNum.png';
      }
      // 2nd Floor: 0.5.jpg - 1.9.jpg
      if (destination.contains('(2/F)') || destination.contains('President')) {
        return 'assets/floors/2nd_floor/1.$stairNum.jpg';
      }
      // 3rd Floor: 2.0.jpg - 2.7.jpg
      if (destination.contains('(3/F)') || destination.contains('Forensic')) {
        return 'assets/floors/3rd_floor/2.$stairNum.jpg';
      }
      // 4th Floor: Starts at 6.jpg
      if (destination.contains('401') || destination.contains('Speech Lab')) {
        return 'assets/floors/4th_floor/${5 + stairNum}.jpg';
      }
      // 5th Floor: Starts at 28.jpg
      if (destination.contains('521') || destination.contains('524')) {
        return 'assets/floors/5th_floor/${27 + stairNum}.jpg';
      }
      // 6th Floor: Starts at 55.jpg
      if (destination.contains('Restaurant') ||
          destination.contains('UC Bar')) {
        return 'assets/floors/6th_floor/${54 + stairNum}.jpg';
      }
      // 7th Floor: Starts at 66.jpg
      if (destination.contains('Hotel') || destination.contains('Gym')) {
        return 'assets/floors/7th_floor/${65 + stairNum}.jpg';
      }

      return 'assets/location/str-$stairNum.png';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                getNavigationImage(),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) =>
                    const Center(child: Text("Photo Not Found")),
              ),
            ),
            const SizedBox(height: 10),
            ...instructions.map(
              (step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.directions, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(step, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
