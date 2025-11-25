// Defines the allowed categories for user feedback, matching the DB enum.
enum FeedbackType {
  bugReport,
  featureRequest,
  generalFeedback,
  other, // Added 'other' type to match the UI options
}

// Helper to convert the enum to a readable string for display and storage.
// This string should match the values in your MySQL 'feedback_type' enum:
// ('Bug Report', 'Feature Request', 'General Feedback', 'Other')
String feedbackTypeToString(FeedbackType type) {
  switch (type) {
    case FeedbackType.bugReport:
      return 'Bug Report';
    case FeedbackType.featureRequest:
      return 'Feature Request';
    case FeedbackType.generalFeedback:
      return 'General Feedback';
    case FeedbackType.other:
      return 'Other';
  }
}

// Converts a string retrieved from the database back to the enum.
FeedbackType stringToFeedbackType(String? type) {
  switch (type) {
    case 'Bug Report':
      return FeedbackType.bugReport;
    case 'Feature Request':
      return FeedbackType.featureRequest;
    case 'General Feedback':
      return FeedbackType.generalFeedback;
    case 'Other':
      return FeedbackType.other;
    default:
      // Fallback for unexpected or missing values
      return FeedbackType.generalFeedback;
  }
}

class FeedbackItem {
  // The 'id' field may be used for retrieving or updating feedback, but
  // it is null when creating a new item.
  final int? id;

  // NOTE: For now, we hardcode the userId in the UI since we don't have a
  // live user session management. You will replace this later.
  final String userId;
  final FeedbackType type;
  final String subject;
  final String message;
  final int? rating; // Optional rating (1-5 in your UI, 0-11 in your DB schema)

  // The status and submittedAt fields are typically managed by the MySQL backend,
  // but we include them for completeness when receiving data (e.g., viewing past submissions).
  final String status;
  final DateTime? submittedAt; // Nullable for new submissions

  FeedbackItem({
    this.id,
    required this.userId,
    required this.type,
    required this.subject,
    required this.message,
    this.rating,
    this.status = 'New',
    this.submittedAt,
  });

  // --- Serialization for Sending Data (Converting to JSON for REST API) ---
  // The backend will handle the 'submitted_at' and potentially 'status'.
  Map<String, dynamic> toJson() {
    return {
      // The backend (API/PHP) will typically map 'id' to the MySQL AUTO_INCREMENT field
      'user_id': userId,
      'feedback_type': feedbackTypeToString(type),
      'subject': subject,
      'message': message,
      'rating': rating,
      // 'status' and 'submitted_at' are often omitted when *creating* a new record
    };
  }

  // --- Deserialization for Receiving Data (Converting from JSON from REST API) ---
  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    // Note: We expect the database to return a string for submitted_at
    // that we can parse into a DateTime.
    DateTime? parsedSubmittedAt;
    if (json['submitted_at'] != null) {
      // This assumes your MySQL timestamp is returned as an ISO 8601 string
      parsedSubmittedAt = DateTime.tryParse(json['submitted_at'].toString());
    }

    return FeedbackItem(
      id: json['feedback_id'] as int?,
      userId: json['user_id'] as String,
      type: stringToFeedbackType(json['feedback_type'] as String?),
      subject: json['subject'] as String,
      message: json['message'] as String,
      rating: json['rating'] as int?,
      status: json['status'] as String,
      submittedAt: parsedSubmittedAt,
    );
  }
}
