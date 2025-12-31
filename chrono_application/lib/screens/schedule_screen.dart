import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// --- SERVICE/MODEL IMPORTS ---
import '../services/api_service.dart';
import '../models/personal_event.dart';
import '../models/schedule_entry.dart'; // REQUIRED IMPORT
import 'add_personal_event_screen.dart';

// Constants (using the provided values)
const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kAccentColor = Color(0xFF4CAF50);
const Color kCourseColor = Color(0xFF7CB342);
const double kBorderRadius = 12.0;
const Color kTableBorderColor = Color(0xFFE9EEF6);

// Dark/light theme aware base colors
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kCardBackground = Color.fromRGBO(255, 255, 255, 1);

enum ViewMode { day, week, month, year }

enum ModalViewMode { weekly, daily }

// REQUIRED FIX: Using records for structured return type (Dart 3+)
typedef ScheduleResult = ({
  List<PersonalEvent> personalEvents,
  List<ScheduleEntry> courseSchedules,
});

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<ScheduleResult> _scheduleFuture;
  ViewMode _currentView = ViewMode.day;
  DateTime _currentDate = DateTime.now();
  // ignore: unused_field
  final DateTime _today = DateTime.now();

  final String headerIllustrationPath = 'assets/images/flowchart.png';

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _loadEvents();
  }

  // Helper to safely calculate alpha value from opacity double
  int _alphaFromOpacity(double opacity) =>
      (opacity * 255).round().clamp(0, 255);

  Future<ScheduleResult> _loadEvents() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    final personalEvents = await apiService.fetchPersonalEvents();
    final courseSchedules = await apiService.fetchUserSchedules().then(
      (list) => list.whereType<ScheduleEntry>().toList(),
    );

    return (personalEvents: personalEvents, courseSchedules: courseSchedules);
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _scheduleFuture = _loadEvents();
    });
    try {
      await _scheduleFuture;
    } catch (_) {}
  }

  void _navigateToAddEvent() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPersonalEventScreen(onEventCreated: _refreshEvents),
      ),
    );
    _refreshEvents();
  }

  void _handleEditEvent(PersonalEvent event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPersonalEventScreen(
          eventToEdit: event,
          onEventCreated: _refreshEvents,
        ),
      ),
    );
    _refreshEvents();
  }

  void _handleDeleteEvent(PersonalEvent event) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final apiService = Provider.of<ApiService>(dialogCtx, listen: false);
        return AlertDialog(
          title: const Text('Delete event?'),
          content: Text('Delete "${event.eventName}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                try {
                  await apiService.deletePersonalEvent(event.id.toString());
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.of(dialogCtx).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${event.eventName}" deleted')),
                  );
                  _refreshEvents();
                } catch (e) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.of(dialogCtx).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // 🎯 FIX 2: Corrected method visibility and logic
  void changeView(ViewMode newMode) {
    if (_currentView != newMode) {
      setState(() {
        _currentView = newMode;
        _currentDate = DateTime.now();
        _scheduleFuture = _loadEvents();
      });
    }
  }

  // 🎯 FIX 3: Corrected method visibility and logic
  void changeDate(int amount) {
    setState(() {
      switch (_currentView) {
        case ViewMode.day:
          _currentDate = _currentDate.add(Duration(days: amount));
          break;
        case ViewMode.week:
          _currentDate = _currentDate.add(Duration(days: amount * 7));
          break;
        case ViewMode.month:
          _currentDate = DateTime(
            _currentDate.year,
            _currentDate.month + amount,
            _currentDate.day,
          );
          break;
        case ViewMode.year:
          _currentDate = DateTime(
            _currentDate.year + amount,
            _currentDate.month,
            _currentDate.day,
          );
          break;
      }
      _scheduleFuture = _loadEvents();
    });
  }

  String _getNavigationTitle() {
    switch (_currentView) {
      case ViewMode.day:
        return DateFormat('EEEE, MMM d, yyyy').format(_currentDate);
      case ViewMode.week:
        final startOfWeek = _currentDate.subtract(
          Duration(days: _currentDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
      case ViewMode.month:
        return DateFormat('MMMM yyyy').format(_currentDate);
      case ViewMode.year:
        return DateFormat('yyyy').format(_currentDate);
    }
  }

  List<PersonalEvent> _filterEvents(List<PersonalEvent> events) {
    DateTime rangeStart;
    DateTime rangeEnd;
    switch (_currentView) {
      case ViewMode.day:
        rangeStart = DateTime(
          _currentDate.year,
          _currentDate.month,
          _currentDate.day,
        );
        rangeEnd = rangeStart
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        break;
      case ViewMode.week:
        rangeStart = _currentDate.subtract(
          Duration(days: _currentDate.weekday - 1),
        );
        rangeEnd = rangeStart
            .add(const Duration(days: 7))
            .subtract(const Duration(milliseconds: 1));
        break;
      case ViewMode.month:
        rangeStart = DateTime(_currentDate.year, _currentDate.month, 1);
        rangeEnd = DateTime(
          _currentDate.year,
          _currentDate.month + 1,
          1,
        ).subtract(const Duration(milliseconds: 1));
        break;
      case ViewMode.year:
        rangeStart = DateTime(_currentDate.year, 1, 1);
        rangeEnd = DateTime(
          _currentDate.year + 1,
          1,
          1,
        ).subtract(const Duration(milliseconds: 1));
        break;
    }

    return events.where((event) {
      final s = event.startDate;
      final e = event.endDate ?? event.startDate;
      final intersects = !(e.isBefore(rangeStart) || s.isAfter(rangeEnd));
      return intersects;
    }).toList();
  }

  // --- Dark mode aware colors ---
  Color _surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color.fromARGB(255, 44, 40, 40)
      : kSurfaceColor;

  Color _cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color.fromARGB(255, 81, 81, 79)
      : kCardBackground;

  Color _textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      // 🎯 DEPRECATED FIX: Use explicit alpha value
      ? Colors.white.withAlpha(_alphaFromOpacity(0.9))
      : const Color.fromARGB(221, 0, 0, 0);

  Color _subTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.grey[400]!
      : Colors.grey.shade600;

  Color _mutedIconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white38
      : Colors.black45;

  // 🎯 FIX 4: Removed unused declaration, using function directly
  Color tableBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      // 🎯 DEPRECATED FIX
      ? Colors.grey.withAlpha(_alphaFromOpacity(0.16))
      : kTableBorderColor;

  // --- UI Pieces (Sliver Components) ---

  // 🎯 FIX 5: Renamed function from _buildHeaderSliver to buildHeaderSliver
  Widget buildHeaderSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        color: _surfaceColor(context),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _cardColor(context),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withAlpha(_alphaFromOpacity(0.3))
                        : Colors.black.withAlpha(_alphaFromOpacity(0.04)),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  headerIllustrationPath,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, st) =>
                      Icon(Icons.map_outlined, color: kPrimaryColor, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Viewer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _textColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getNavigationTitle(),
                    style: TextStyle(color: _subTextColor(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshEvents,
              icon: Icon(Icons.refresh_rounded, color: _textColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeChips() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Wrap(
          spacing: 8,
          children: ViewMode.values.map((mode) {
            final isSelected = mode == _currentView;
            return ChoiceChip(
              label: Text(mode.name.toUpperCase()),
              selected: isSelected,
              // 🎯 FIX 2: Correct call to non-private method
              onSelected: (_) => changeView(mode),
              selectedColor: kPrimaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : _textColor(context),
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: isSelected
                  ? kPrimaryColor
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey.shade200),
              side: BorderSide(
                color: isSelected
                    ? kPrimaryColor.withAlpha(_alphaFromOpacity(0.2))
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade400),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateNavigationBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Row(
          children: [
            IconButton(
              // 🎯 FIX 3: Correct call to non-private method
              onPressed: () => changeDate(-1),
              icon: Icon(
                Icons.chevron_left_rounded,
                color: _textColor(context),
              ),
            ),
            Expanded(
              child: Text(
                _getNavigationTitle(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textColor(context),
                ),
              ),
            ),
            IconButton(
              // 🎯 FIX 3: Correct call to non-private method
              onPressed: () => changeDate(1),
              icon: Icon(
                Icons.chevron_right_rounded,
                color: _textColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalEventCard(PersonalEvent event) {
    final startTime = DateFormat('h:mm a').format(event.startDate);
    final endTime = event.endDate != null
        ? DateFormat('h:mm a').format(event.endDate!)
        : null;
    final color = event.eventType == 'Course' ? kCourseColor : kAccentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Dismissible(
        key: ValueKey(
          'event-${event.id}-${event.startDate.millisecondsSinceEpoch}',
        ),
        onDismissed: (_) => _handleDeleteEvent(event),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_forever, color: Colors.white),
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
          ),
          elevation: 2,
          color: _cardColor(context),
          child: InkWell(
            borderRadius: BorderRadius.circular(kBorderRadius),
            onTap: () => _handleEditEvent(event),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // time column
                  Container(
                    width: 74,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startTime,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (endTime != null) const SizedBox(height: 4),
                        if (endTime != null)
                          Text(
                            'to $endTime',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.eventName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _textColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.location != null && event.location!.isNotEmpty
                              ? '📍 ${event.location}'
                              : (event.eventType ?? 'Personal'),
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: _cardColor(context),
                    onSelected: (val) {
                      if (val == 'edit') _handleEditEvent(event);
                      if (val == 'delete') _handleDeleteEvent(event);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: _mutedIconColor(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(color: _textColor(context)),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 NEW WIDGET: Build List of Uploaded Schedules (Classes)
  Widget _buildScheduleCard(ScheduleEntry entry) {
    final startTime = entry.startTime;
    final endTime = entry.endTime;
    final color = kCourseColor;

    // Convert dayOfWeek string (MWF) to a displayable schedule description
    final String scheduleDesc =
        '${entry.dayOfWeek ?? 'N/A'} | ${entry.room ?? 'N/A'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Dismissible(
        // Placeholder key for required Dismissible widget
        key: ValueKey(entry.scheduleCode),
        onDismissed: (_) {
          // TODOImplement deleting ScheduleEntry if needed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Course ${entry.scheduleCode} dismissed (Deletion not yet implemented).',
              ),
            ),
          );
        },
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_forever, color: Colors.white),
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
          ),
          elevation: 1,
          color: _cardColor(context),
          child: InkWell(
            borderRadius: BorderRadius.circular(kBorderRadius),
            onTap: () {
              // Future extension: Allow editing ScheduleEntry from here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Course: ${entry.scheduleCode} - ${entry.title}',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Time/Icon Column
                  Container(
                    width: 74,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startTime,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (endTime != null && endTime.isNotEmpty)
                          const SizedBox(height: 4),
                        if (endTime != null && endTime.isNotEmpty)
                          Text(
                            'to $endTime',
                            style: TextStyle(
                              fontSize: 12,
                              color: _subTextColor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.scheduleCode,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _textColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.title,
                          style: TextStyle(
                            color: _subTextColor(context),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scheduleDesc,
                          // 🎯 DEPRECATED FIX: Using explicit alpha value
                          style: TextStyle(
                            color: _subTextColor(
                              context,
                            ).withAlpha(_alphaFromOpacity(0.8)),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: _mutedIconColor(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 FIX 5: Corrected method visibility and logic
  Widget buildEventsAndCoursesList(
    List<PersonalEvent> personalEvents,
    List<ScheduleEntry> courseSchedules,
  ) {
    // 1. Filter Course Schedules based on current date view
    final filteredCourseSchedules = courseSchedules.where((e) {
      if (_currentView == ViewMode.day && e.dayOfWeek != null) {
        final currentDayAbbr = DateFormat(
          'E',
        ).format(_currentDate).toUpperCase().substring(0, 1);
        return e.dayOfWeek!.contains(currentDayAbbr);
      }
      return true;
    }).toList();

    // 2. Filter Personal Events
    final filteredEvents = _filterEvents(
      personalEvents,
    ); // 🎯 FIX 14: filteredEvents is now used

    // Combine lists for rendering
    final List<Widget> listItems = [];

    // A. Add course schedules (The classes)
    if (filteredCourseSchedules.isNotEmpty) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'UPLOADED CLASSES',
            style: TextStyle(fontWeight: FontWeight.bold, color: kCourseColor),
          ),
        ),
      );
      listItems.addAll(
        filteredCourseSchedules.map((e) => _buildScheduleCard(e)),
      );
    }

    // 2. Add filtered personal events
    if (filteredEvents.isNotEmpty) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'PERSONAL EVENTS',
            style: TextStyle(fontWeight: FontWeight.bold, color: kAccentColor),
          ),
        ),
      );
      // Build the list of personal event cards
      listItems.addAll(filteredEvents.map((e) => _buildPersonalEventCard(e)));
    }

    // Handle empty state
    if (listItems.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 68,
                // 🎯 DEPRECATED FIX
                color: Theme.of(
                  context,
                ).hintColor.withAlpha(_alphaFromOpacity(0.4)),
              ),
              const SizedBox(height: 12),
              Text(
                'No events or classes for ${DateFormat('EEE, MMM d').format(_currentDate)}',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _navigateToAddEvent,
                icon: const Icon(Icons.add),
                label: const Text('Add Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Return the combined list in a SliverList
    return SliverList(delegate: SliverChildListDelegate(listItems));
  }

  // 🎯 FIX 6: Renamed function from _buildMonthlyGrid to buildMonthlyCalendar
  Widget buildMonthlyCalendar(int month, int year, List<PersonalEvent> events) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final eventsByDay = <int, List<PersonalEvent>>{};
    for (var e in events.where(
      (ev) => ev.startDate.month == month && ev.startDate.year == year,
    )) {
      eventsByDay.putIfAbsent(e.startDate.day, () => []).add(e);
    }

    final cells = <Widget>[];
    // Add weekday headers
    final weekdays = DateFormat.E().dateSymbols.STANDALONEWEEKDAYS;
    for (int i = 0; i < 7; i++) {
      cells.add(
        Center(
          child: Text(
            weekdays[(i + 1) % 7].substring(0, 1), // S, M, T, W, T, F, S
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              // 🎯 DEPRECATED FIX
              color: _textColor(context).withAlpha(_alphaFromOpacity(0.5)),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      // 🎯 FIX 16: Use DateTime.now() instead of unused _today
      final isToday =
          DateTime.now().year == year &&
          DateTime.now().month == month &&
          DateTime.now().day == d;
      final hasEvent = eventsByDay.containsKey(d);
      cells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _currentView = ViewMode.day;
              _currentDate = DateTime(year, month, d);
              _scheduleFuture = _loadEvents();
            });
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isToday
                  ? kPrimaryColor.withAlpha(_alphaFromOpacity(0.10))
                  : (Theme.of(context).brightness == Brightness.dark
                        ? _cardColor(context)
                        : Colors.white),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasEvent
                    ? kPrimaryColor.withAlpha(_alphaFromOpacity(0.4))
                    // 🎯 FIX 4: Using direct function call
                    : tableBorderColor(context),
              ),
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$d',
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: isToday
                        ? kPrimaryColor
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87),
                  ),
                ),
                if (hasEvent)
                  Positioned(
                    bottom: 6,
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kAccentColor,
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

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kBorderRadius),
          color: _cardColor(context),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              DateFormat('MMMM yyyy').format(firstDay),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textColor(context),
              ),
            ),
            const SizedBox(height: 12),
            // Use aspect ratio 1.2 for better day cell height after adding headers
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              physics: const NeverScrollableScrollPhysics(),
              children: cells,
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 FIX 7: Renamed to avoid collision and accepting ScheduleEntry list
  Widget _buildDailyCourseModalList(
    List<ScheduleEntry> courseSchedules, [
    ScrollController? scrollController,
  ]) {
    if (courseSchedules.isEmpty) {
      return Center(
        child: Text(
          'No courses scheduled.',
          // 🎯 DEPRECATED FIX
          style: TextStyle(
            color: _textColor(context).withAlpha(_alphaFromOpacity(0.7)),
          ),
        ),
      );
    }

    // Group courses by day (e.g., 'M', 'T', 'W')
    final coursesByDay = <String, List<ScheduleEntry>>{};
    for (var e in courseSchedules) {
      final days = e.dayOfWeek?.split('');
      if (days != null) {
        for (var day in days) {
          coursesByDay.putIfAbsent(day, () => []).add(e);
        }
      }
    }

    // Sort keys by traditional weekday order (M, T, W, H, F, S)
    const dayOrder = ['M', 'T', 'W', 'H', 'F', 'S'];
    final sortedKeys = coursesByDay.keys.toList()
      ..sort((a, b) {
        final aIndex = dayOrder.indexOf(a);
        final bIndex = dayOrder.indexOf(b);
        return aIndex.compareTo(bIndex);
      });

    return ListView(
      controller: scrollController, // Apply controller here
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: sortedKeys.map((dayAbbr) {
        final list = coursesByDay[dayAbbr]!
          // Assume start_time is in HH:MM:SS format and sort by time
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        final dayName = _mapDayAbbreviation(dayAbbr);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kCourseColor,
                ),
              ),
              const SizedBox(height: 6),
              ...list.map((entry) {
                // Safely handle potentially short time strings
                final start = entry.startTime.substring(
                  0,
                  min(5, entry.startTime.length),
                );
                final end = entry.endTime != null && entry.endTime!.isNotEmpty
                    ? entry.endTime!.substring(0, min(5, entry.endTime!.length))
                    : '?';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.scheduleCode,
                    style: TextStyle(
                      color: _textColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '$start - $end • ${entry.room ?? 'N/A'}',
                    style: TextStyle(
                      // 🎯 DEPRECATED FIX
                      color: _textColor(
                        context,
                      ).withAlpha(_alphaFromOpacity(0.6)),
                    ),
                  ),
                  dense: true,
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper to map single letter abbreviation to full day name
  String _mapDayAbbreviation(String abbr) {
    switch (abbr) {
      case 'M':
        return 'MONDAY';
      case 'T':
        return 'TUESDAY';
      case 'W':
        return 'WEDNESDAY';
      case 'H':
        return 'THURSDAY';
      case 'F':
        return 'FRIDAY';
      case 'S':
        return 'SATURDAY';
      default:
        return abbr;
    }
  }

  void _showCourseScheduleViewer(ScheduleResult result) {
    final courseSchedules = result.courseSchedules;

    ModalViewMode initialView = ModalViewMode.weekly;

    // 🎯 FIX 10: Renamed local variable to conform to Dart style
    Widget buildModalContent(ModalViewMode view, ScrollController controller) {
      if (view == ModalViewMode.weekly) {
        return _buildEmptyWeeklyPlaceholder(controller);
      } else {
        return _buildDailyCourseModalList(courseSchedules, controller);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            ModalViewMode modalCurrentView = initialView;

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // Drag Handle
                      Center(
                        child: Container(
                          width: 64,
                          height: 6,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white12
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Header - MODIFIED TO INCLUDE ADD/UPLOAD BUTTON
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // New: Add/Upload Course Button (Left side)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color:
                                    kPrimaryColor, // Use primary color for action
                                onPressed: () {
                                  // This is the placeholder for the Course Upload/Management navigation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tapped: Navigate to Course Upload/Management screen.',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Title (Center)
                            Center(
                              child: Text(
                                'Course Schedule',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _textColor(context),
                                ),
                              ),
                            ),

                            // Close Button (Right side)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: _textColor(context),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // END MODIFIED HEADER

                      // Segmented Control
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white12
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Weekly Tab
                              Expanded(
                                child: InkWell(
                                  onTap: () => setModalState(() {
                                    initialView = ModalViewMode.weekly;
                                    modalCurrentView = ModalViewMode.weekly;
                                  }),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          modalCurrentView ==
                                              ModalViewMode.weekly
                                          ? kPrimaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Weekly',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            modalCurrentView ==
                                                ModalViewMode.weekly
                                            ? Colors.white
                                            : _textColor(
                                                context,
                                                // ignore: deprecated_member_use
                                              ).withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Daily Tab
                              Expanded(
                                child: InkWell(
                                  onTap: () => setModalState(() {
                                    initialView = ModalViewMode.daily;
                                    modalCurrentView = ModalViewMode.daily;
                                  }),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          modalCurrentView ==
                                              ModalViewMode.daily
                                          ? kPrimaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Daily',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            modalCurrentView ==
                                                ModalViewMode.daily
                                            ? Colors.white
                                            : _textColor(
                                                context,
                                                // ignore: deprecated_member_use
                                              ).withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // CONTENT AREA
                      Expanded(
                        child: buildModalContent(
                          modalCurrentView,
                          scrollController,
                        ),
                      ),

                      // Footer Button
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16.0,
                          top: 8.0,
                        ),
                        child: Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 16,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // WEEKLY PLACEHOLDER (EMPTY)
  Widget _buildEmptyWeeklyPlaceholder(ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Text(
            'Weekly view is currently empty',
            style: TextStyle(
              // 🎯 DEPRECATED FIX
              color: _textColor(context).withAlpha(_alphaFromOpacity(0.6)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // We are now expecting a combined result from the future
    return FutureBuilder<ScheduleResult>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        final ScheduleResult? result = snapshot.data;
        // 🎯 FIX 6: Correctly handling null result data
        final List<PersonalEvent> allEvents = result?.personalEvents ?? [];
        final List<ScheduleEntry> courseSchedules =
            result?.courseSchedules ?? [];

        // FIX 14: filteredEvents is no longer needed locally

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        return Scaffold(
          backgroundColor: _surfaceColor(context),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _navigateToAddEvent,
            label: const Text('Add Event'),
            icon: const Icon(Icons.add),
            backgroundColor: kPrimaryColor,
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: _surfaceColor(context),
                  elevation: 0,
                  surfaceTintColor: _surfaceColor(context),
                  toolbarHeight: 72,
                  title: Row(
                    children: [
                      Text(
                        'Schedule Viewer',
                        style: TextStyle(
                          color: _textColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(label: Text(_currentView.name.toUpperCase())),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today_outlined,
                        color: _textColor(context),
                      ),
                      onPressed: () => _showCourseScheduleViewer(result!),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _refreshEvents,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: _textColor(context),
                      ),
                    ),
                  ],
                ),
                // --- Calendar Navigation ---
                _buildViewModeChips(),
                _buildDateNavigationBar(),

                // --- Main Content Display ---

                // Content based on view mode (Month/Year)
                if (_currentView == ViewMode.month ||
                    _currentView == ViewMode.year)
                  SliverToBoxAdapter(
                    child: _currentView == ViewMode.month
                        // 🎯 FIX 7: Correctly calling buildMonthlyCalendar
                        ? buildMonthlyCalendar(
                            _currentDate.month,
                            _currentDate.year,
                            allEvents, // Personal Events for calendar dots
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(
                                12,
                                (i) => SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 2 -
                                      28,
                                  // 🎯 FIX 7: Correctly calling buildMonthlyCalendar
                                  child: buildMonthlyCalendar(
                                    i + 1,
                                    _currentDate.year,
                                    allEvents,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  )
                // Day/Week View: Show both Course Schedules and Personal Events
                else
                  // 🎯 FIX 5: Correctly calling buildEventsAndCoursesList
                  buildEventsAndCoursesList(allEvents, courseSchedules),
              ],
            ),
          ),
        );
      },
    );
  }
}
