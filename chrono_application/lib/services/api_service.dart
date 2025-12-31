// lib/services/api_service.dart

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- SERVICE/MODEL IMPORTS ---
import '../models/announcement.dart';
import '../models/ticket.dart';
import '../models/personal_event.dart';
import '../models/calendar_event.dart';
import '../models/schedule_entry.dart';

import '../models/route_coordinate.dart';

// --- Host Configuration (FIXED PORT TO 3001) ---
// Android Emulator Host: Must use 10.0.2.2 to reach the Windows host machine.
const String kApiHost = 'http://10.0.2.2:3001';
// Localhost Host: Used for iOS Simulator/Desktop/Web.
const String kLocalhostHost = 'http://localhost:3001';

//-------------------------------------------------------

// --- ApiService Class ---
class ApiService {
  final String _baseUrl = '$kApiHost/api';
  final _storage = const FlutterSecureStorage();

  // --- Utility Methods (Internal URL Resolution Logic) ---

  String _resolveUrl(String path) {
    if (path.startsWith(kLocalhostHost)) {
      return path.replaceFirst(kLocalhostHost, kApiHost);
    }

    if (!path.startsWith('http')) {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      return '$kApiHost/$cleanPath';
    }

    return path;
  }

  String resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    return _resolveUrl(imagePath);
  }

  String resolveProfileUrl(String? profileImgPath) {
    if (profileImgPath == null || profileImgPath.isEmpty) {
      return '';
    }
    return _resolveUrl(profileImgPath);
  }

  Map<String, dynamic> _safeDecode(String body, int statusCode) {
    try {
      final decoded = json.decode(body);
      // Ensure the decoded object is a Map
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      // If the top-level structure is a List (e.g., for fetchUserTickets or fetchAnnouncements, or fetchPersonalEvents),
      // return it wrapped under the key 'list'.
      if (decoded is List<dynamic>) {
        return {'list': decoded}; // <--- THIS IS THE KEY USED FOR LISTS
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
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }

    return headers;
  }

  /// NEW HELPER: Sends an authenticated HTTP request (GET/POST/PUT/DELETE)
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
        if (response.statusCode == 204) return {};
        // CRUCIAL: This returns the Map (which may contain the 'list' wrapper key)
        return _safeDecode(response.body, response.statusCode);
      } else {
        String errorMessage = failureMessage;
        try {
          final errorBody = _safeDecode(response.body, response.statusCode);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
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

      final photoPath = user['photo_url'] ?? user['profile_img'];
      if (photoPath is String && photoPath.isNotEmpty) {
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

      final photoPath = user['photo_url'] ?? user['profile_img'];
      if (photoPath is String && photoPath.isNotEmpty) {
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

  // lib/services/api_service.dart (Schedule Management Methods)

  //------------------------------------------------------------------------
  // --- Schedule Management Methods (Using New Helper) ---
  //------------------------------------------------------------------------

  /// Uploads extracted schedule data (manual form submission) to the server.
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
    // UPDATED: Changed parameter name from 'location' to 'room'
    String? room,
  }) async {
    // NOTE: Assuming _sendAuthenticatedRequest is available in this class
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
        // UPDATED: Changed JSON key from 'location' to 'room'
        'room': room,
      },
      failureMessage: 'Failed to upload schedule.',
    );
    return {
      'success': true,
      'message': response['message'],
      'id': response['id'],
    };
  }

  /// Uploads a PDF file containing schedule data via Multipart form.
  Future<Map<String, dynamic>> uploadSchedulePdf(
    File pdfFile,
    String userId, // The userId parameter is redundant but kept for now.
  ) async {
    final url = Uri.parse('$_baseUrl/upload/schedule_file');
    final token = await getToken();

    if (token == null) {
      throw Exception('Authentication token is missing. Please log in again.');
    }

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.files.add(
      await http.MultipartFile.fromPath('schedule_file', pdfFile.path),
    );

    // IMPROVEMENT: Removed 'user_id' from request.fields
    // (As decided previously, the server securely extracts it from the JWT token)
    // request.fields['user_id'] = userId;

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log(
        'Schedule PDF upload status: ${response.statusCode}',
        name: 'ApiService',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeDecode(response.body, response.statusCode);
        return data;
      } else {
        String errorMessage = 'Failed to upload schedule file.';
        try {
          final errorBody = _safeDecode(response.body, response.statusCode);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {}
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
  Future<Map<String, dynamic>> saveExtractedSchedules(
    List<Map<String, dynamic>> extractedSchedules,
  ) async {
    // NOTE: Assuming _sendAuthenticatedRequest is defined/available
    final response = await _sendAuthenticatedRequest(
      'schedules/bulk_save',
      'POST',
      body: {'schedules': extractedSchedules},
      failureMessage: 'Failed to save batch of extracted schedules.',
    );

    return {
      'success': true,
      'message':
          response['message'] ??
          'Successfully saved ${extractedSchedules.length} schedules.',
      'saved_count': response['saved_count'] ?? extractedSchedules.length,
    };
  }

  // lib/services/api_service.dart (Inside ApiService class)

  /// Updates a single schedule entry after manual correction.
  Future<Map<String, dynamic>> updateScheduleEntry(ScheduleEntry entry) async {
    // Use the entry's toJson() method for the body, as it contains all fields
    final Map<String, dynamic> body = entry.toJson();

    // Ensure the entry ID is available for the URL
    if (entry.id == null) {
      throw Exception('Cannot update schedule: Entry ID is missing.');
    }

    // This calls the Node.js PUT /api/schedules/update/:id route
    final response = await _sendAuthenticatedRequest(
      'schedules/update/${entry.id}', // Uses the permanent ID in the URL
      'PUT', // Uses the PUT HTTP method
      body: body,
      failureMessage: 'Failed to update schedule entry.',
    );

    return response;
  }

  /// Fetches all general uploaded schedules (from add_pdf table).
  Future<List<ScheduleEntry>> fetchUserSchedules() async {
    final data = await _sendAuthenticatedRequest(
      'schedules',
      'GET',
      failureMessage: 'Failed to load user schedules.',
    );

    // Node route returns a Map wrapped response: {success: true, schedules: [...]}
    // We expect the server to return 'schedules' key containing the list.
    final List<dynamic> jsonList = data['schedules'] as List<dynamic>? ?? [];

    // FIX: Map to ScheduleEntry
    return jsonList
        .cast<Map<String, dynamic>>()
        .map((json) => ScheduleEntry.fromJson(json))
        .toList();
  }

  // lib/services/api_service.dart (Inside ApiService class)

  /// Deletes a single schedule entry from the database.
  Future<Map<String, dynamic>> deleteScheduleEntry(String scheduleId) async {
    // NOTE: Assuming _sendAuthenticatedRequest is available in this class
    final response = await _sendAuthenticatedRequest(
      'schedules/delete/$scheduleId', // New DELETE route
      'DELETE', // Uses the DELETE HTTP method
      failureMessage: 'Failed to delete schedule entry.',
    );

    return response;
  }

  // ------------------------------------------------------------------------
  // --- AUTHENTICATION HELPER ---
  // ------------------------------------------------------------------------

  /// Retrieves the authenticated user's ID.
  /// This method simulates fetching the user ID from stored authentication data.
  Future<String?> getUserId() async {
    // ------------------------------------------------------------------
    // IMPORTANT: In a real app, replace '123' with logic that
    // extracts the user ID from your stored JWT token or session manager.
    // For now, this placeholder resolves the compilation error.
    // ------------------------------------------------------------------

    // Example placeholder:
    await Future.delayed(
      const Duration(milliseconds: 50),
    ); // Simulate async delay
    return '123';
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
        'is_personal': true,
      },
      failureMessage: 'Failed to create personal event.',
    );

    final eventJson =
        (responseBody['event'] ?? responseBody) as Map<String, dynamic>;
    return PersonalEvent.fromJson(eventJson);
  }

  /// Updates an existing personal event.
  Future<void> updatePersonalEvent(PersonalEvent event) async {
    if (event.id == null) {
      throw Exception('Cannot update event: ID is missing.');
    }

    await _sendAuthenticatedRequest(
      'events/personal/${event.id}',
      'PUT',
      body: event.toJson(),
      failureMessage: 'Failed to update event.',
    );
  }

  /// Deletes a personal event by ID.
  Future<void> deletePersonalEvent(String eventId) async {
    await _sendAuthenticatedRequest(
      'events/personal/$eventId',
      'DELETE',
      failureMessage: 'Failed to delete event.',
    );
  }

  // lib/services/api_service.dart (Check this method)

  /// Fetches all personal events for the currently authenticated user.
  Future<List<PersonalEvent>> fetchPersonalEvents() async {
    final responseBody = await _sendAuthenticatedRequest(
      'events/personal',
      'GET',
      failureMessage: 'Failed to fetch personal events. Check token status.',
    );

    // 1. SUCCESS CASE: Check if the response is a List. (Expected behavior)
    // The server (Node.js) directly returns a List/Array of events for this endpoint: res.json(formattedEvents);

    // Check if the response body contains the 'list' key (from _safeDecode wrapper)
    final List<dynamic> eventList =
        responseBody['list'] as List<dynamic>? ?? [];

    return eventList.map((json) => PersonalEvent.fromJson(json)).toList();
  }

  // -----------------------------------------------------------------------------
  // --- Calendar Event Management (CRUD - Using New Helper) ---
  // -----------------------------------------------------------------------------

  /// Fetches calendar events for the authenticated user.
  /// Returns a list of CalendarEvent objects from the calendar_events table.
  Future<List<CalendarEvent>> fetchCalendarEvents() async {
    final responseBody = await _sendAuthenticatedRequest(
      'events/calendar',
      'GET',
      failureMessage: 'Failed to fetch calendar events. Check token status.',
    );

    // The server returns the list inside the 'list' key ({list: [...]})
    final List<dynamic> eventList =
        responseBody['list'] as List<dynamic>? ?? [];

    return eventList.map((json) => CalendarEvent.fromJson(json)).toList();
  }

  // NEW: Creates a new calendar event (POST /api/events/calendar)
  Future<CalendarEvent> createCalendarEvent(CalendarEvent event) async {
    final responseBody = await _sendAuthenticatedRequest(
      'events/calendar',
      'POST',
      body: event.toJson(),
      failureMessage: 'Failed to create calendar event.',
    );

    // Server returns the created event object inside the 'event' key.
    final eventJson = responseBody['event'] as Map<String, dynamic>;
    return CalendarEvent.fromJson(eventJson);
  }

  // NEW: Updates an existing calendar event (PUT /api/events/calendar/:id)
  Future<CalendarEvent> updateCalendarEvent(CalendarEvent event) async {
    if (event.id == 0) {
      throw Exception('Cannot update event: ID is missing or invalid.');
    }

    final responseBody = await _sendAuthenticatedRequest(
      'events/calendar/${event.id}',
      'PUT',
      body: event.toJson(), // Use the corrected camelCase payload
      failureMessage: 'Failed to update calendar event.',
    );

    // Server returns the updated event object inside the 'event' key.
    final eventJson = responseBody['event'] as Map<String, dynamic>;
    return CalendarEvent.fromJson(eventJson);
  }

  // NEW: Deletes a calendar event by ID (DELETE /api/events/calendar/:id)
  Future<void> deleteCalendarEvent(int eventId) async {
    await _sendAuthenticatedRequest(
      'events/calendar/$eventId',
      'DELETE',
      failureMessage: 'Failed to delete calendar event.',
    );
  }

  // --- Profile Management ---
  /// Fetches the user's profile data (requires token).
  Future<Map<String, dynamic>> fetchProfile() async {
    final data = await _sendAuthenticatedRequest(
      'profile',
      'GET',
      failureMessage: 'Failed to fetch profile.',
    );

    final photoPath = data['photo_url'] ?? data['profile_img'];
    if (photoPath is String && photoPath.isNotEmpty) {
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

    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.fields['name'] = name;
    request.fields['course'] = course;
    request.fields['department'] = department;

    if (profilePhoto != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profilePhoto', profilePhoto.path),
      );
    }

    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);

    if (response.statusCode == 200) {
      final data = _safeDecode(response.body, response.statusCode);
      Map<String, dynamic> user = data['user'] as Map<String, dynamic>;

      final photoPath = user['photo_url'] ?? user['profile_img'];
      if (photoPath is String && photoPath.isNotEmpty) {
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
    await _sendAuthenticatedRequest(
      'user/change-password',
      'POST',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      failureMessage: 'Password change failed.',
    );
  }

  /// Handles the token-authenticated request to logically deactivate the user's account.
  Future<void> deactivateAccount({required String currentPassword}) async {
    await _sendAuthenticatedRequest(
      'user/deactivate',
      'POST',
      body: {'currentPassword': currentPassword},
      failureMessage: 'Account deactivation failed.',
    );

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
    return {'success': true, 'message': 'Feedback submitted successfully!'};
  }

  // ------------------------------------------------------------------------------
  // --- HELP CENTER / TICKET METHODS (Using New Helper) ---
  // ------------------------------------------------------------------------------

  /// Submits a new support ticket to the server.
  Future<Ticket> submitNewTicket(String subject, String message) async {
    final responseBody = await _sendAuthenticatedRequest(
      'tickets',
      'POST',
      body: {'subject': subject, 'message': message},
      failureMessage: 'Failed to submit ticket.',
    );

    return Ticket.fromJson(responseBody['ticket'] as Map<String, dynamic>);
  }

  /// Fetches all support tickets for the authenticated user.
  Future<List<Ticket>> fetchUserTickets() async {
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

  // ------------------------------------------------------------------------
  // --- NAVIGATION AND ROUTING METHODS ---
  // ------------------------------------------------------------------------

  /// Requests the shortest path from a starting POI (Staircase) to a destination POI.
  /// NOTE: Signature updated to support cross-floor routing using POI IDs and floors.
  Future<List<RouteCoordinate>> calculateRoute({
    // ignore: non_constant_identifier_names
    required String startPOI_ID, // NEW: e.g., "Stair 1 - Floor 5"
    // ignore: non_constant_identifier_names
    required String destinationPOI_ID, // EXISTING
    required String startFloorID, // NEW: e.g., "level5"
    required String destinationFloorID, // NEW: e.g., "level1"
  }) async {
    // --------------------------------------------------------------------
    // IMPORTANT: The backend API call body must also be updated to match
    // the new parameters. I am assuming a new structure here.
    // --------------------------------------------------------------------
    final body = {
      'startPOI_ID': startPOI_ID, // Using the new starting POI
      'destinationPOI_ID': destinationPOI_ID,
      'startFloorID': startFloorID,
      'destinationFloorID': destinationFloorID,
      // We remove 'startCoords' and the single 'floorID' parameter
    };

    try {
      // Calls the POST /api/v1/route endpoint
      final response = await http.post(
        Uri.parse('$kApiHost/api/v1/route'),
        // Assuming your backend requires authentication headers for this route
        headers: await _getAuthHeaders(isJson: true),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pathJson = data['path'] as List<dynamic>;

        // Map the list of JSON objects to a list of RouteCoordinate models
        return pathJson
            .map(
              (jsonItem) =>
                  RouteCoordinate.fromJson(jsonItem as Map<String, dynamic>),
            )
            .toList();
      } else {
        // Handle 404/400 errors from the server (e.g., POI not found)
        final errorBody = _safeDecode(response.body, response.statusCode);
        // The error key from the server is 'error' (e.g., {"error": "..."})
        final errorMessage =
            errorBody['error'] ??
            'Route calculation failed with status: ${response.statusCode}.';

        // Throw the specific error message returned by the Node.js backend
        throw Exception(errorMessage);
      }
    } on http.ClientException {
      throw Exception(
        'Network error: Could not connect to the routing service.',
      );
    } catch (e) {
      log('Routing API Error: $e', name: 'NavigationService');
      rethrow;
    }
  }

  // ---------------------------CLEAR CACHE DATA----------------------------------------

  // Handles the token-authenticated request to clear server-side cache and
  /// triggers local token deletion (logout) on success.
  Future<void> clearCachedData() async {
    // 1. Call the API endpoint to signal clearance (server check/cleanup)
    await _sendAuthenticatedRequest(
      'user/clear-cache', // The new endpoint
      'POST',
      body: {}, // Empty body required for POST type
      failureMessage: 'Failed to signal server-side cache clearance.',
    );

    // 2. If the server call succeeds (200 OK), delete the local authentication token
    //    and any stored profile data. This forces a logout.
    await deleteToken();

    // The AuthWrapper (main.dart) will handle the local data clearance upon state change.
  }

  // ------------------------------------------------------------------------------

  // --- Announcement Management (Using New Helper) ---

  /// Fetches a list of announcements (requires token).
  Future<List<Announcement>> fetchAnnouncements() async {
    try {
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
