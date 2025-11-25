import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// NOTE: These imports assume your files are structured correctly
import '../models/announcement.dart';
import '../services/api_service.dart';

// The ApiService instance (we instantiate it once for use in the screen)
// NOTE: ApiService must now ONLY contain methods relevant to data fetching.
// The image URL resolver methods are no longer needed for these simplified Announcements.
final ApiService _apiService = ApiService();

// Convert to StatefulWidget to manage loading and data state
class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _error; // To hold any error message

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  // Method to fetch data from the API using the real ApiService
  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fetchedAnnouncements = await _apiService.fetchAnnouncements();
      setState(() {
        _announcements = fetchedAnnouncements;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('Exception:')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Failed to load announcements. Please check your connection.';
        debugPrint('Error fetching announcements: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // NOTE: The _buildProfileImage helper method has been removed,
  // and its logic is now inline using a simple placeholder icon.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Bulletin Board'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchAnnouncements,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Text(
          'No announcements found.',
          style: TextStyle(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    // Display the list of announcements
    return RefreshIndicator(
      onRefresh: _fetchAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final post = _announcements[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Author and Date Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Author Name and Placeholder Icon
                      Row(
                        children: [
                          // Replaced _buildProfileImage with a simple placeholder CircleAvatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(80),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.authorName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      // Published Date
                      Text(
                        DateFormat('MMM d, yyyy').format(post.publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // Title
                  Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // NOTE: AnnouncementImageWidget call removed from here.

                  // Content
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
