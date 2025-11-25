// lib/models/ticket.dart (The file content you provided)

import 'dart:convert';

class Ticket {
  // Fields based on usage in TicketItem and database structure
  final int id;
  final String subject;
  final String message;
  final String status;
  final String?
  adminReply; // Nullable based on database 'admin_reply' being NULL
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Note: user_id is in the DB but not needed for display here

  const Ticket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    this.adminReply,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a Ticket from a JSON map (e.g., from an API response)
  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse strings to DateTime, handling nulls or invalid formats
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null; // Handle parsing error
        }
      }
      return null;
    }

    return Ticket(
      id: json['id'] as int,
      subject: json['subject'] as String,
      message: json['message'] as String,
      // Default to 'open' or ensure the status field is present and a string
      status: json['status'] as String? ?? 'open',
      // Handle the nullable field
      adminReply: json['admin_reply'] as String?,
      // Parse the timestamp fields
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  // Helper method for decoding a list of tickets
  static List<Ticket> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Ticket.fromJson(json)).toList();
  }
}
