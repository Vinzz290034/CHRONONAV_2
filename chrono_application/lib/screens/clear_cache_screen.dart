// lib/screens/clear_cache_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ClearCacheScreen extends StatefulWidget {
  // This callback handles the final action (logging out and state change) in AuthWrapper
  final VoidCallback onClearSuccess;

  const ClearCacheScreen({super.key, required this.onClearSuccess});

  @override
  State<ClearCacheScreen> createState() => _ClearCacheScreenState();
}

class _ClearCacheScreenState extends State<ClearCacheScreen> {
  bool _isLoading = false;

  Future<void> _attemptClearCache() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // 1. Call the API service to clear token/server cache
      await apiService.clearCachedData();

      // 2. Execute the success callback (which triggers the logout/UI change in main.dart)
      if (mounted) {
        widget.onClearSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Clearance failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color dangerColor = Color(0xFFC62828); // Deep Red
    const Color chrononaPrimaryColor = Color(0xFF007A5A); // Green

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clear Cached Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: dangerColor,
              size: 80,
            ),
            const SizedBox(height: 20),

            Text(
              'Permanent Action Required',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // --- Warning Box ---
            Card(
              // ignore: deprecated_member_use
              color: dangerColor.withOpacity(0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to proceed?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Clearing cached data will perform the following irreversible actions:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text('• You will be immediately logged out.'),
                    const Text('• Your session token will be destroyed.'),
                    const Text(
                      '• All local profile data (name, email, photo) will be deleted.',
                    ),
                    const Text(
                      '• The app will need to re-download all data upon next login.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- Action Button ---
            ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.delete_forever),
              label: Text(
                _isLoading ? 'Processing...' : 'Clear Cache and Log Out',
              ),
              onPressed: _isLoading ? null : _attemptClearCache,
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // --- Cancel Button ---
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: chrononaPrimaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
