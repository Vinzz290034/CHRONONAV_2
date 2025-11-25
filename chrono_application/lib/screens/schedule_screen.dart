import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// --- SERVICE/MODEL IMPORTS ---
import '../services/api_service.dart';
import '../models/personal_event.dart';
import 'add_personal_event_screen.dart';

// Constants
const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kAccentColor = Color(0xFF4CAF50);
const Color kCourseColor = Color(0xFF7CB342);
const double kBorderRadius = 12.0;
const Color kTableBorderColor = Color(0xFFE9EEF6);

// Dark/light theme aware base colors
const Color kSurfaceColor = Color(
  0xFFF5F5F5,
); // Scaffold background (light mode)
const Color kCardBackground = Color.fromRGBO(
  255,
  255,
  255,
  1,
); // Card background (light mode)

enum ViewMode { day, week, month, year }

enum ModalViewMode { weekly, daily }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<PersonalEvent>> _eventsFuture;
  ViewMode _currentView = ViewMode.day;
  DateTime _currentDate = DateTime.now();
  final DateTime _today = DateTime.now();

  final String headerIllustrationPath = 'assets/images/flowchart.png';

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
  }

  int _alphaFromOpacity(double opacity) =>
      (opacity * 255).round().clamp(0, 255);

  Future<List<PersonalEvent>> _loadEvents() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return apiService.fetchUserSchedules();
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _eventsFuture = _loadEvents();
    });
    try {
      await _eventsFuture;
    } catch (_) {}
  }

  void _navigateToAddEvent() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPersonalEventScreen(onEventCreated: _refreshEvents),
      ),
    );
    if (!mounted) return;
    if (result == true) _refreshEvents();
  }

  void _handleEditEvent(PersonalEvent event) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPersonalEventScreen(
          eventToEdit: event,
          onEventCreated: _refreshEvents,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) _refreshEvents();
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

  void _changeView(ViewMode newMode) {
    if (_currentView != newMode) {
      setState(() {
        _currentView = newMode;
        _currentDate = DateTime.now();
        _eventsFuture = _loadEvents();
      });
    }
  }

  void _changeDate(int amount) {
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
      _eventsFuture = _loadEvents();
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
      ? const Color.fromARGB(
          255,
          44,
          40,
          40,
        ) // dark scaffold background (slightly bluish-black)
      : kSurfaceColor;

  Color _cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color.fromARGB(255, 81, 81, 79) // dark card background
      : kCardBackground;

  Color _textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      // ignore: deprecated_member_use
      ? Colors.white.withOpacity(0.9)
      : const Color.fromARGB(221, 0, 0, 0);

  Color _subTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.grey[400]!
      : const Color.fromARGB(255, 255, 255, 255);

  Color _mutedIconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white38
      : Colors.black45;

  Color _tableBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      // ignore: deprecated_member_use
      ? Colors.grey.withOpacity(0.16)
      : kTableBorderColor;

  // --- UI Pieces ---
  Widget _buildHeader(BuildContext context) {
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
                    'My Schedule',
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
              onSelected: (_) => _changeView(mode),
              selectedColor: kPrimaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : _textColor(context),
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: isSelected
                  ? kPrimaryColor
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : _subTextColor(context)),
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
              onPressed: () => _changeDate(-1),
              icon: Icon(
                Icons.chevron_left_rounded,
                color: _subTextColor(context),
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
              onPressed: () => _changeDate(1),
              icon: Icon(
                Icons.chevron_right_rounded,
                color: _subTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(PersonalEvent event) {
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
            onTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(event.eventName))),
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
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
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

  Widget _buildEventsList(List<PersonalEvent> events) {
    if (events.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 68,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color.fromARGB(31, 253, 0, 0)
                    : Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No events for ${DateFormat('EEE, MMM d').format(_currentDate)}',
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

    events.sort((a, b) => a.startDate.compareTo(b.startDate));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildEventCard(events[index]),
        childCount: events.length,
      ),
    );
  }

  // Monthly calendar grid widget (compact)
  Widget _buildMonthlyGrid(int month, int year, List<PersonalEvent> events) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final eventsByDay = <int, List<PersonalEvent>>{};
    for (var e in events.where(
      (ev) => ev.startDate.month == month && ev.startDate.year == year,
    )) {
      eventsByDay.putIfAbsent(e.startDate.day, () => []).add(e);
    }

    final cells = <Widget>[];
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final isToday =
          _today.year == year && _today.month == month && _today.day == d;
      final hasEvent = eventsByDay.containsKey(d);
      cells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _currentView = ViewMode.day;
              _currentDate = DateTime(year, month, d);
              _eventsFuture = _loadEvents();
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
                    ? kPrimaryColor.withAlpha(_alphaFromOpacity(0.12))
                    : _tableBorderColor(context),
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
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              physics: const NeverScrollableScrollPhysics(),
              children: cells,
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseScheduleViewer(List<PersonalEvent> allEvents) {
    final courseEvents = allEvents
        .where((e) => e.eventType == 'Course' && e.endDate != null)
        .toList();

    ModalViewMode initialView = ModalViewMode.weekly;

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

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                        child: modalCurrentView == ModalViewMode.weekly
                            ? _buildEmptyWeeklyPlaceholder(scrollController)
                            : _buildDailyCourseList(
                                courseEvents,
                                scrollController,
                              ),
                      ),

                      // Footer Button
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16.0,
                          top: 8.0,
                        ),
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
              fontSize: 16,
              // ignore: deprecated_member_use
              color: _textColor(context).withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCourseList(
    List<PersonalEvent> courseEvents, [
    ScrollController? scrollController,
  ]) {
    if (courseEvents.isEmpty) {
      return Center(
        child: Text(
          'No courses scheduled.',
          style: TextStyle(color: _subTextColor(context)),
        ),
      );
    }
    final coursesByDay = <int, List<PersonalEvent>>{};
    for (var e in courseEvents) {
      coursesByDay.putIfAbsent(e.startDate.weekday, () => []).add(e);
    }
    final sorted = coursesByDay.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: sorted.map((weekday) {
        final dayName = DateFormat(
          'EEEE',
        ).format(DateTime(2025, 1, 6).add(Duration(days: weekday - 1)));
        final list = coursesByDay[weekday]!
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kCourseColor,
                ),
              ),
              const SizedBox(height: 6),
              ...list.map((ev) {
                final start = DateFormat('h:mm a').format(ev.startDate);
                final end = DateFormat('h:mm a').format(ev.endDate!);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    ev.eventName,
                    style: TextStyle(color: _textColor(context)),
                  ),
                  subtitle: Text(
                    '$start - $end • ${ev.location ?? 'Online'}',
                    style: TextStyle(color: _subTextColor(context)),
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

  @override
  Widget build(BuildContext context) {
    // Use RefreshIndicator but we need a sliver-compatible approach: wrap in CustomScrollView + pull-to-refresh with a NotificationListener
    return Scaffold(
      backgroundColor: _surfaceColor(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddEvent,
        label: const Text('Add Event'),
        icon: const Icon(Icons.add),
        backgroundColor: kPrimaryColor,
      ),
      body: SafeArea(
        child: FutureBuilder<List<PersonalEvent>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            final events = snapshot.data ?? [];
            return NotificationListener<ScrollNotification>(
              onNotification: (scroll) => false,
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
                          'My Schedule',
                          style: TextStyle(
                            color: _textColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(_currentView.name.toUpperCase()),
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? Colors.white10
                              : Colors.white,
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          color: _textColor(context),
                        ),
                        onPressed: () => _showCourseScheduleViewer(events),
                      ),
                    ],
                  ),
                  _buildHeader(context),
                  _buildViewModeChips(),
                  _buildDateNavigationBar(),
                  // main content
                  if (snapshot.connectionState == ConnectionState.waiting)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            kPrimaryColor,
                          ),
                        ),
                      ),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: _subTextColor(context)),
                        ),
                      ),
                    )
                  else
                  // content based on view
                  if (_currentView == ViewMode.month)
                    SliverToBoxAdapter(
                      child: _buildMonthlyGrid(
                        _currentDate.month,
                        _currentDate.year,
                        events,
                      ),
                    )
                  else if (_currentView == ViewMode.year)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(
                            12,
                            (i) => SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 28,
                              child: _buildMonthlyGrid(
                                i + 1,
                                _currentDate.year,
                                events,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildEventsList(_filterEvents(events)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
