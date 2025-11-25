import 'dart:convert';
import 'dart:developer'; // 🟢 Dart's developer library for logging
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- SERVICE/MODEL IMPORTS ---
import '../models/announcement.dart';
import '../models/ticket.dart';
import '../models/personal_event.dart'; // 💡 Import for PersonalEvent model

// --- Host Configuration ---
// Set this to your actual host IP for testing.
const String kApiHost = 'http://10.0.2.2:3000';
// The host the Node.js server sends back in the photo_url field.
const String kLocalhostHost = 'http://localhost:3000';

// --- ApiService Class ---
class ApiService {
  // Base URL for API endpoints (e.g., http://10.0.2.2:3000/api)
  final String _baseUrl = '$kApiHost/api';

  // Secure storage instance
  final _storage = const FlutterSecureStorage();

  // --- Utility Methods (Internal URL Resolution Logic) ---

  /// Handles the core logic of constructing a public image URL,
  /// replacing server-side 'http://localhost:3000' with the correct
  /// device-accessible API_HOST and handling relative paths.
  String _resolveUrl(String path) {
    if (path.startsWith(kLocalhostHost)) {
      return path.replaceFirst(kLocalhostHost, kApiHost);
    }

    if (!path.startsWith('http')) {
      // Handle relative path (e.g., /uploads/image.jpg or uploads/image.jpg)
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      return '$kApiHost/$cleanPath';
    }

    // If it's already a correct, external http link, return as is
    return path;
  }

  /// Public method required by announcement_screen.dart to resolve image paths.
  String resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return ''; // Return empty string if no path is provided
    }
    return _resolveUrl(imagePath);
  }

  /// Public method required by announcement_screen.dart to resolve profile image paths.
  String resolveProfileUrl(String? profileImgPath) {
    if (profileImgPath == null || profileImgPath.isEmpty) {
      return ''; // Return empty string if no path is provided
    }
    return _resolveUrl(profileImgPath);
  }

  /// Helper to safely decode JSON and provide a fallback error message.
  Map<String, dynamic> _safeDecode(String body, int statusCode) {
    try {
      final decoded = json.decode(body);
      // Ensure the decoded object is a Map
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      // If the top-level structure is a List (e.g., for fetchUserTickets or fetchAnnouncements),
      // return it wrapped under the key 'list'.
      if (decoded is List<dynamic>) {
        return {'list': decoded};
      }
      throw const FormatException();
    } on FormatException {
      throw Exception(
        'Server returned unexpected response (Status: $statusCode).',
      );
    }
  }

  //---------------------------------------------------------------------------
  // --- Token Management ---
  //---------------------------------------------------------------------------
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> _getAuthHeaders({bool isJson = false}) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Authentication token is missing. Please log in again.');
    }

    final Map<String, String> headers = {'Authorization': 'Bearer $token'};

    if (isJson) {
      // Only include Content-Type for JSON payloads
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }

    return headers;
  }

  /// 🟢 NEW HELPER: Sends an authenticated HTTP request (GET/POST/PUT/DELETE)
  /// and handles common errors and decoding.
  Future<Map<String, dynamic>> _sendAuthenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    String failureMessage = 'Request failed.',
  }) async {
    final bool isJson = body != null;
    final headers = await _getAuthHeaders(isJson: isJson);
    final url = Uri.parse('$_baseUrl/$endpoint');

    try {
      http.Response response;
      final encodedBody = isJson ? jsonEncode(body) : null;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: encodedBody);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: encodedBody);
          break;
        case 'DELETE':
          response = await http.delete(
            url,
            headers: headers,
            body: encodedBody,
          );
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      log(
        '$method request to $endpoint status: ${response.statusCode}',
        name: 'ApiService',
      );

      // Success range (200 OK, 201 Created, 204 No Content)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Return empty map for 204 No Content
        if (response.statusCode == 204) return {};
        return _safeDecode(response.body, response.statusCode);
      } else {
        String errorMessage = failureMessage;
        try {
          final errorBody = _safeDecode(response.body, response.statusCode);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          // Fallback if response body is not valid JSON
          errorMessage = 'Server error (Status: ${response.statusCode}).';
        }
        throw Exception(errorMessage);
      }
    } on http.ClientException {
      throw Exception('Network error: Could not connect to the server.');
    } catch (e) {
      rethrow;
    }
  }

  //---------------------------------------------------------------------------
  // --- Core Authentication Methods ---
  //---------------------------------------------------------------------------
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = _safeDecode(response.body, response.statusCode);
      final String token = data['token'];
      await saveToken(token);

      Map<String, dynamic> user = data['user'] as Map<String, dynamic>;

      // Ensure photo_url is a full public URL, using the new resolver logic
      final photoPath = user['photo_url'] ?? user['profile_img'];
      if (photoPath is String && photoPath.isNotEmpty) {
        // Use the internal resolution helper
        user['photo_url'] = _resolveUrl(photoPath);
      }
      user.remove('profile_img');

      return user;
    } else {
      final errorBody = _safeDecode(response.body, response.statusCode);
      String errorMessage =
          errorBody['message'] ??
          'Login failed with status code: ${response.statusCode}';

      if (response.statusCode == 401) {
        throw Exception('Invalid email or password.');
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String fullname,
    required String email,
    required String password,
    required String role,
    required String course,
    required String department,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'fullname': fullname,
        'email': email,
        'password': password,
        'role': role,
        'course': course,
        'department': department,
      }),
    );

    if (response.statusCode == 201) {
      final data = _safeDecode(response.body, response.statusCode);
      final String token = data['token'];
      await saveToken(token);

      Map<String, dynamic> user = data['user'] as Map<String, dynamic>;

      // Ensure photo_url is processed if present, using the new resolver logic
      final photoPath = user['photo_url'] ?? user['profile_img'];
      if (photoPath is String && photoPath.isNotEmpty) {
        // Use the internal resolution helper
        user['photo_url'] = _resolveUrl(photoPath);
      }
      user.remove('profile_img');

      return user;
    } else {
      final errorBody = _safeDecode(response.body, response.statusCode);
      String errorMessage =
          errorBody['message'] ??
          'Registration failed with status code: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  //------------------------------------------------------------------------
  // --- Schedule Management Methods (Using New Helper) ---
  //------------------------------------------------------------------------
  /// Uploads extracted schedule data (JSON payload) to the server.
  Future<Map<String, dynamic>> uploadSchedule({
    required String scheduleCode,
    required String title,
    required String scheduleType,
    required String startDate,
    required String startTime,
    required String repeatFrequency,
    String? description,
    String? endDate,
    String? endTime,
    String? dayOfWeek,
    String? location,
  }) async {
    // 🟢 Refactored to use new helper
    final response = await _sendAuthenticatedRequest(
      'upload_schedule',
      'POST',
      body: {
        'schedule_code': scheduleCode,
        'title': title,
        'description': description,
        'schedule_type': scheduleType,
        'start_date': startDate,
        'end_date': endDate,
        'start_time': startTime,
        'end_time': endTime,
        'day_of_week': dayOfWeek,
        'repeat_frequency': repeatFrequency,
        'location': location,
      },
      failureMessage: 'Failed to upload schedule.',
    );
    // Assuming the server returns success message or ID in the response body
    return {
      'success': true,
      'message': response['message'],
      'id': response['id'],
    };
  }

  /// Uploads a PDF file containing schedule data via Multipart form. (Kept separate as it's Multipart)
  Future<Map<String, dynamic>> uploadSchedulePdf(
    File pdfFile,
    String userId,
  ) async {
    // Note: The endpoint below should match your server route for file uploads.
    final url = Uri.parse('$_baseUrl/upload/schedule_file');
    final token = await getToken();

    if (token == null) {
      throw Exception('Authentication token is missing. Please log in again.');
    }

    // Create a multipart request
    var request = http.MultipartRequest('POST', url);

    // Add JWT Authorization Header
    request.headers.addAll({'Authorization': 'Bearer $token'});

    // Add the PDF file
    // 'schedule_file' must match the key expected by your backend server's file handler
    request.files.add(
      await http.MultipartFile.fromPath('schedule_file', pdfFile.path),
    );

    // Add other form fields (like user ID)
    request.fields['user_id'] = userId;

    try {
      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log(
        'Schedule PDF upload status: ${response.statusCode}',
        name: 'ApiService',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        final data = _safeDecode(response.body, response.statusCode);
        return data;
      } else {
        // Server returned an error status code
        String errorMessage = 'Failed to upload schedule file.';
        try {
          final errorBody = _safeDecode(response.body, response.statusCode);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          // Fallback if response body is not valid JSON
        }
        throw Exception(errorMessage);
      }
    } on http.ClientException {
      throw Exception(
        'Network error: Could not connect to the server for PDF upload.',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Saves a list of schedules that were extracted (e.g., from a PDF processing job).
  /// This method is designed for batch insertion of standardized schedule data.
  Future<Map<String, dynamic>> saveExtractedSchedules(
    List<Map<String, dynamic>> extractedSchedules,
  ) async {
    // 🟢 Refactored to use new helper
    final response = await _sendAuthenticatedRequest(
      'schedules/batch_save', // Endpoint for bulk schedule saving
      'POST',
      // Send the list of schedules nested under the key 'schedules' in the request body
      body: {'schedules': extractedSchedules},
      failureMessage: 'Failed to save batch of extracted schedules.',
    );

    // The server should ideally return a count of records saved or a success message
    return {
      'success': true,
      'message':
          response['message'] ??
          'Successfully saved ${extractedSchedules.length} schedules.',
      'saved_count': response['saved_count'] ?? extractedSchedules.length,
    };
  }

  /// Fetches all personal schedules/events for the authenticated user.
  Future<List<PersonalEvent>> fetchUserSchedules() async {
    // 🟢 Refactored to use new helper
    final data = await _sendAuthenticatedRequest(
      'events/personal',
      'GET',
      failureMessage: 'Failed to load user schedules.',
    );

    // The Node route returns a List of objects directly, which is mapped to 'list'
    final List<dynamic> jsonList = data['list'] as List<dynamic>? ?? [];

    return jsonList
        .cast<Map<String, dynamic>>()
        // Map the raw response JSON to the PersonalEvent model
        .map((json) => PersonalEvent.fromJson(json))
        .toList();
  }

  // -----------------------------------------------------------------------------
  // --- Personal Event Management (CRUD - Using New Helper) ---
  // -----------------------------------------------------------------------------

  /// Submits a new personal event to the server.
  Future<PersonalEvent> createPersonalEvent({
    required String eventName,
    String? description,
    required String startDate, // ISO 8601 string including time
    String? endDate, // ISO 8601 string including time
    String? location,
    String? eventType,
  }) async {
    // 🟢 Refactored to use new helper
    final responseBody = await _sendAuthenticatedRequest(
      'events/personal',
      'POST',
      body: {
        'event_name': eventName,
        'description': description,
        'start_date': startDate,
        'end_date': endDate,
        'location': location,
        'event_type': eventType,
        'is_personal': true, // Always true for this endpoint
      },
      failureMessage: 'Failed to create personal event.',
    );

    // Assuming the server returns the created event wrapped under an 'event' key,
    // or returns the object directly.
    final eventJson =
        (responseBody['event'] ?? responseBody) as Map<String, dynamic>;
    return PersonalEvent.fromJson(eventJson);
  }

  /// Updates an existing personal event.
  Future<void> updatePersonalEvent(PersonalEvent event) async {
    // Ensure the ID is present before attempting to update
    if (event.id == null) {
      throw Exception('Cannot update event: ID is missing.');
    }

    // 🟢 Refactored to use new helper
    await _sendAuthenticatedRequest(
      'events/personal/${event.id}',
      'PUT',
      body: event.toJson(), // The helper encodes the body
      failureMessage: 'Failed to update event.',
    );
  }

  /// Deletes a personal event by ID.
  Future<void> deletePersonalEvent(String eventId) async {
    // 🟢 Refactored to use new helper
    await _sendAuthenticatedRequest(
      'events/personal/$eventId',
      'DELETE',
      failureMessage: 'Failed to delete event.',
    );
  }

  //--------------------------------------------------------------------------
  // --- Profile Management ---
  //--------------------------------------------------------------------------
  /// Fetches the user's profile data (requires token).
  Future<Map<String, dynamic>> fetchProfile() async {
    // 🟢 Refactored to use new helper
    final data = await _sendAuthenticatedRequest(
      'profile',
      'GET',
      failureMessage: 'Failed to fetch profile.',
    );

    // Ensure client-side path construction and host replacement is handled, using the new resolver logic
    final photoPath = data['photo_url'] ?? data['profile_img'];
    if (photoPath is String && photoPath.isNotEmpty) {
      // Use the internal resolution helper
      data['photo_url'] = _resolveUrl(photoPath);
    }
    data.remove('profile_img');

    return data;
  }

  /// Updates user profile details and optionally uploads a photo using Multipart. (Kept separate as it's Multipart)
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String course,
    required String department,
    File? profilePhoto, // Optional file to upload (dart:io File)
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication token is missing. Please log in again.');
    }

    final url = Uri.parse('$_baseUrl/profile');
    var request = http.MultipartRequest('POST', url);

    // Add JWT Authorization Header (no Content-Type needed for Multipart)
    request.headers.addAll({'Authorization': 'Bearer $token'});

    // Add text fields
    request.fields['name'] = name;
    request.fields['course'] = course;
    request.fields['department'] = department;

    // Add file if present
    if (profilePhoto != null) {
      // 'profilePhoto' must match the key used in server.js: upload.single('profilePhoto')
      request.files.add(
        await http.MultipartFile.fromPath('profilePhoto', profilePhoto.path),
      );
    }

    // Send the request
    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);

    if (response.statusCode == 200) {
      final data = _safeDecode(response.body, response.statusCode);
      Map<String, dynamic> user = data['user'] as Map<String, dynamic>;

      // Ensure photo_url is processed if present in the response, using the new resolver logic
      final photoPath = user['photo_url'] ?? user['profile_img'];
      if (photoPath is String && photoPath.isNotEmpty) {
        // Use the internal resolution helper
        user['photo_url'] = _resolveUrl(photoPath);
      }
      user.remove('profile_img');

      return user;
    } else {
      try {
        final errorBody = _safeDecode(response.body, response.statusCode);
        throw Exception(
          errorBody['message'] ??
              'Profile update failed with status: ${response.statusCode}',
        );
      } catch (e) {
        // Handle cases where body is not JSON or decoding failed
        throw Exception(
          'Profile update failed with status: ${response.statusCode}. Error: $e',
        );
      }
    }
  }

  // --- Security Management (Using New Helper) ---

  /// Handles the token-authenticated request to change the user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // 🟢 Refactored to use new helper
    await _sendAuthenticatedRequest(
      'user/change-password',
      'POST',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      failureMessage: 'Password change failed.',
    );
  }

  /// Handles the token-authenticated request to logically deactivate the user's account.
  Future<void> deactivateAccount({required String currentPassword}) async {
    // 🟢 Refactored to use new helper
    await _sendAuthenticatedRequest(
      'user/deactivate',
      'POST',
      body: {'currentPassword': currentPassword},
      failureMessage: 'Account deactivation failed.',
    );

    // Success: Delete the local JWT token immediately
    await deleteToken();
  }

  //------------------------------------------------------------------------
  // --- Feedback Management (Using New Helper) ---
  //------------------------------------------------------------------------
  /// Submits user feedback (requires token).
  Future<Map<String, dynamic>> submitFeedback({
    required String subject,
    required String message,
    required String feedbackType,
    required int rating,
  }) async {
    // 🟢 Refactored to use new helper
    await _sendAuthenticatedRequest(
      'feedback',
      'POST',
      body: {
        'subject': subject,
        'message': message,
        'feedback_type': feedbackType,
        'rating': rating,
      },
      failureMessage: 'Failed to submit feedback.',
    );
    // Return success message on successful 200/201/204 response
    return {'success': true, 'message': 'Feedback submitted successfully!'};
  }

  // ------------------------------------------------------------------------------
  // --- HELP CENTER / TICKET METHODS (Using New Helper) ---
  // ------------------------------------------------------------------------------

  /// Submits a new support ticket to the server.
  Future<Ticket> submitNewTicket(String subject, String message) async {
    // 🟢 Refactored to use new helper
    final responseBody = await _sendAuthenticatedRequest(
      'tickets',
      'POST',
      body: {'subject': subject, 'message': message},
      failureMessage: 'Failed to submit ticket.',
    );

    // FIX: Ensure 'ticket' key exists and cast value to Map<String, dynamic>
    return Ticket.fromJson(responseBody['ticket'] as Map<String, dynamic>);
  }

  /// Fetches all support tickets for the authenticated user.
  Future<List<Ticket>> fetchUserTickets() async {
    // 🟢 Refactored to use new helper
    final data = await _sendAuthenticatedRequest(
      'tickets',
      'GET',
      failureMessage: 'Failed to load tickets.',
    );

    // FIX: Server returns a list, which is wrapped in 'list' by _safeDecode.
    final List<dynamic> jsonList = data['list'] as List<dynamic>;

    return jsonList
        .cast<Map<String, dynamic>>()
        .map((json) => Ticket.fromJson(json))
        .toList();
  }
  // ------------------------------------------------------------------------------

  // --- Announcement Management (Using New Helper) ---

  /// Fetches a list of announcements (requires token).
  Future<List<Announcement>> fetchAnnouncements() async {
    try {
      // 🟢 Refactored to use new helper
      final data = await _sendAuthenticatedRequest(
        'announcements',
        'GET',
        failureMessage: 'Failed to load announcements.',
      );

      // FIX: Prioritize extracting the list from the custom 'list' wrapper.
      final List<dynamic> jsonList =
          data['list'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          data['announcements'] as List<dynamic>? ??
          [];

      // Convert the raw JSON list to a list of Announcement objects
      return jsonList.cast<Map<String, dynamic>>().map((json) {
        return Announcement.fromJson(json);
      }).toList();
    } on Exception catch (e) {
      // Explicitly check for 404/No Content errors in the exception message from the helper
      if (e.toString().contains('404')) {
        log(
          'Announcements endpoint returned 404/Not Found, returning empty list.',
          name: 'ApiService',
        );
        return [];
      }
      rethrow;
    }
  }
}
