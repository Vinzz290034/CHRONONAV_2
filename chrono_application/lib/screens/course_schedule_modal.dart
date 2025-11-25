//lib/screen/schedule/course_schedule_modal.dart
import 'package:flutter/material.dart';
import '../../models/personal_event.dart';

class CourseScheduleModal extends StatelessWidget {
  final PersonalEvent event;

  // ignore: use_super_parameters
  const CourseScheduleModal({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.eventName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (event.description != null)
              Text(event.description!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text("Start: ${event.startDate}", style: theme.textTheme.bodySmall),
            if (event.endDate != null)
              Text("End: ${event.endDate}", style: theme.textTheme.bodySmall),
            if (event.location != null)
              Text(
                "Location: ${event.location}",
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
