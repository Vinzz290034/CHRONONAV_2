import 'package:flutter/material.dart';

// Defines the available feedback types based on the ENUM in your DB:
// enum('Bug Report', 'Feature Request', 'General Feedback')
enum FeedbackType { bugReport, featureRequest, generalFeedback }

class FeedbackScreen extends StatefulWidget {
  final VoidCallback onBackToSettings;
  // Handler to process the submitted data (e.g., send to API/DB)
  final void Function(Map<String, dynamic> feedbackData) onSubmitFeedback;

  const FeedbackScreen({
    required this.onBackToSettings,
    required this.onSubmitFeedback,
    super.key,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _subject;
  String? _message;
  FeedbackType _feedbackType = FeedbackType.generalFeedback;
  double _rating = 5.0; // Default rating out of 10

  // Helper to convert Enum to display string
  String _getFeedbackTypeString(FeedbackType type) {
    switch (type) {
      case FeedbackType.bugReport:
        return 'Bug Report';
      case FeedbackType.featureRequest:
        return 'Feature Request';
      case FeedbackType.generalFeedback:
        return 'General Feedback';
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final feedbackData = {
        // Map to DB column names:
        'feedback_type': _getFeedbackTypeString(_feedbackType),
        'subject': _subject,
        'message': _message,
        'rating': _rating.round(), // int(11) in DB
      };

      // Call the external handler to process the data
      widget.onSubmitFeedback(feedbackData);

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thank you! Your feedback has been submitted.')),
      );
      widget.onBackToSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToSettings,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- Feedback Type (DB Column: feedback_type) ---
              const Text(
                'Feedback Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              DropdownButtonFormField<FeedbackType>(
                value: _feedbackType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: FeedbackType.values.map((FeedbackType type) {
                  return DropdownMenuItem<FeedbackType>(
                    value: type,
                    child: Text(_getFeedbackTypeString(type)),
                  );
                }).toList(),
                onChanged: (FeedbackType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _feedbackType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // --- Subject (DB Column: subject) ---
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Subject (e.g., Login Issue, New Feature Idea)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _subject = value;
                },
              ),
              const SizedBox(height: 20),

              // --- Message (DB Column: message) ---
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Detailed Message',
                  hintText: 'Describe the issue or request in detail.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'A message is required.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _message = value;
                },
              ),
              const SizedBox(height: 20),

              // --- Rating (DB Column: rating) ---
              Row(
                children: [
                  const Text(
                    'Satisfaction Rating (1-10):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _rating.round().toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _rating,
                min: 1,
                max: 10,
                divisions: 9,
                label: _rating.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
              const SizedBox(height: 30),

              // --- Submit Button ---
              Center(
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Feedback'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
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
