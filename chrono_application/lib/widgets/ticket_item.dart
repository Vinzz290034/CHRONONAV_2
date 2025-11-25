import 'package:flutter/material.dart';
import '../models/ticket.dart';
import 'package:intl/intl.dart';

// Helper function to format DateTime or return a default string
String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return 'N/A';
  }
  // Use a format that includes date and time for clarity
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toLocal());
}

// Helper function for the status indicator color
Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return Colors.blue;
    case 'closed':
      return Colors.green;
    case 'in progress':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

class TicketItem extends StatelessWidget {
  const TicketItem({
    super.key,
    required this.ticket,
    required this.onTap, // Keep this for potential future action
  });

  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Determine if an admin reply exists
    final hasReply = ticket.adminReply != null && ticket.adminReply!.isNotEmpty;

    // The status text/chip for the title bar
    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(ticket.status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ticket.status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        key: PageStorageKey(ticket.id), // Use ticket ID as a unique key
        // Title section: Ticket ID, Subject, and Status Chip
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Ticket #${ticket.id}: ${ticket.subject}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            statusChip,
          ],
        ),

        // Children (Expanded content)
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Submitted Details
                Text(
                  'Submitted: ${_formatDateTime(ticket.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                // User Message
                const Text(
                  'Your Message:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  ticket.message,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),

                // Admin Reply Section (Conditional Display)
                if (hasReply)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen.shade50,
                      border: Border(
                        left: BorderSide(
                          color: Colors.green.shade400,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Reply:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // The fix is to ensure these fields are not null/empty before accessing
                        Text(ticket.adminReply!),
                        if (ticket.updatedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Replied: ${_formatDateTime(ticket.updatedAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // If no reply, show a waiting message
                if (!hasReply && ticket.status.toLowerCase() != 'closed')
                  const Text(
                    'Admin review is pending...',
                    style: TextStyle(color: Colors.orange),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// NOTE: You'll also need the Ticket Model in lib/model/ticket.dart.
