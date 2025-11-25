// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // State variables for feedback_type and rating
  final List<String> _feedbackTypes = const [
    'Bug Report',
    'Feature Request',
    'General Feedback',
  ];
  String? _selectedFeedbackType;
  double _currentRating = 5.0; // Default rating (1-10 range)

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage; // State to hold network/server error message

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    // 1. Perform client-side validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFeedbackType == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a feedback type.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error
    });

    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    try {
      // The ApiService throws an Exception on non-2xx status codes (400, 401, 404, 500)
      // If this line executes without throwing, the submission was successful (status 201).
      final response = await _apiService.submitFeedback(
        subject: subject,
        message: message,
        feedbackType: _selectedFeedbackType!,
        rating: _currentRating.toInt(), // Send as integer (1-10)
      );

      if (mounted) {
        // Successful submission (201 status returned)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Use message from server if available, otherwise a default success message
            content: Text(
              response['message'] ??
                  'Thank you! Feedback submitted successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // On success, navigate back to the profile screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Catch network errors, 401/403 (Auth), 404 (Not Found), 500 (Server Error)
      String messageToShow = 'Submission failed: An unknown error occurred.';

      // Attempt to extract error message from the exception if available
      if (e.toString().contains('message:')) {
        // e.g., Exception: Status 400 - {"message":"All fields are required."}
        final match = RegExp(r'"message":"(.*?)"').firstMatch(e.toString());
        messageToShow = match?.group(1) ?? messageToShow;
      } else if (e.toString().contains('401')) {
        messageToShow = 'Authentication required. Please log in again.';
      } else if (e.toString().contains('404')) {
        // Critical: Remind the user to restart the server!
        messageToShow =
            'Server error (404 Not Found). Check server URL/path, or RESTART your Node.js server!';
      } else {
        messageToShow = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Status ', 'Server Error: ');
      }

      if (mounted) {
        setState(() {
          _errorMessage = messageToShow;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messageToShow),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Send Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Feedback Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFeedbackType,
                decoration: const InputDecoration(
                  labelText: 'Feedback Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                hint: const Text('Select a type'),
                items: _feedbackTypes.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFeedbackType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a feedback type.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Subject Field
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                  helperText:
                      'e.g., App Crashes on Start, Request for Dark Mode',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Message Field
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  hintText: 'Describe your feedback or issue in detail...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Message cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Rating Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Satisfaction Rating:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${_currentRating.toInt()} / 10',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _currentRating,
                min: 1,
                max: 10,
                divisions: 9, // 1 to 10 inclusive, so 9 divisions
                label: _currentRating.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _currentRating = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Error Message Display
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitFeedback,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isLoading ? 'Submitting...' : 'Send Feedback',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green[700], // Use a distinct color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
