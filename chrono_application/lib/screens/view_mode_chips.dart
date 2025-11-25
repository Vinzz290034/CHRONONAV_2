import 'package:flutter/material.dart';

// Removed: import '../../screens/schedule_screen.dart';
// That file no longer contains the ViewMode enum, and importing it caused the conflict.

import '../../models/view_mode.dart'; // The single, authoritative source for ViewMode

class ViewModeChips extends StatelessWidget {
  final ViewMode currentView;
  // Using Function(ViewMode) is acceptable, but void Function(ViewMode) is more explicit/safer
  final void Function(ViewMode) onViewChange;

  // Updated to use super parameters for better practice
  const ViewModeChips({
    super.key,
    required this.currentView,
    required this.onViewChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8,
        children: ViewMode.values.map((view) {
          final isSelected = currentView == view;
          return ChoiceChip(
            label: Text(
              // Using .name for enums is modern Flutter/Dart practice
              view.name.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            onSelected: (_) => onViewChange(view),
          );
        }).toList(),
      ),
    );
  }
}
