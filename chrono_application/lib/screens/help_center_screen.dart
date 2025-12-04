// lib/screens/help_center_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Ensure correct path
import '../models/ticket.dart'; // Ensure correct path
import '../widgets/ticket_item.dart'; // This widget now handles the reply display

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final ApiService _apiService = ApiService();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- Data Fetching and Submission Logic ---

  Future<void> _fetchTickets() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fetchedTickets = await _apiService.fetchUserTickets();
      setState(() {
        _tickets = fetchedTickets.toList().cast<Ticket>();

        // FIX: Safely handle nullable DateTime objects during sorting (descending order)
        _tickets.sort((a, b) {
          // If both are null, they are equal in order.
          if (a.createdAt == null && b.createdAt == null) return 0;
          // If 'a' is null, put it after 'b' (return 1 for descending).
          if (a.createdAt == null) return 1;
          // If 'b' is null, put it after 'a' (return -1 for descending).
          if (b.createdAt == null) return -1;

          // Compare non-null DateTime objects for descending order (b before a).
          return b.createdAt!.compareTo(a.createdAt!);
        });
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load tickets: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitTicket() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final newTicket = await _apiService.submitNewTicket(
          _subjectController.text,
          _messageController.text,
        );

        // Add the new ticket to the list and clear inputs
        setState(() {
          _tickets.insert(0, newTicket); // Add to the top (newest first)
          _subjectController.clear();
          _messageController.clear();
        });

        if (mounted) {
          // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket submitted successfully!')),
          );
        }
      } catch (e) {
        setState(() {
          // Clean up error message for display
          _error = e.toString().contains('Exception:')
              ? e.toString().replaceFirst('Exception: ', '')
              : 'An error occurred during submission.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _viewTicketDetails(Ticket ticket) {
    // Since TicketItem is an ExpansionTile, this is now just a placeholder action.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing Ticket #${ticket.id}: ${ticket.subject}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: RefreshIndicator(
        // Added RefreshIndicator for pulling down to refresh tickets
        onRefresh: _fetchTickets,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Ensures scrolling even if content is small
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- New Support Ticket Section ---
              const Text(
                'Send us a message (New Support Ticket)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Subject cannot be empty.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Your Message *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Message cannot be empty.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitTicket,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Submit Ticket',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // --- Ticket History Section ---
              const Text(
                'Your Support Tickets History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (_isLoading && _tickets.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (_tickets.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('You have not submitted any tickets yet.'),
                  ),
                )
              else
                // Renders the list of TicketItem widgets
                Column(
                  children: _tickets.map((ticket) {
                    return TicketItem(
                      ticket: ticket,
                      // onTap will run the placeholder _viewTicketDetails action
                      onTap: () => _viewTicketDetails(ticket),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // --- FAQ Section ---
              const Text(
                'FAQs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const ExpansionTile(
                // Added const for performance
                title: Text('How do I reset my password?'),
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'You can reset your password from the Profile screen under Security settings.',
                    ),
                  ),
                ],
              ),
              const ExpansionTile(
                // Added const for performance
                title: Text('How can I report a bug?'),
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Please submit a new support ticket using the form above and select "Bug Report" as the category (if applicable to your UI/Model).',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
