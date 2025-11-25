import 'package:flutter/material.dart';

/// Utility class to show custom, non-blocking messages (Snackbars)
/// this is for add_pdf_screen
/// instead of using native alerts.
class ModalUtils {
  static void showMessage(
    BuildContext context,
    String message, {
    Color? color,
    IconData? icon,
  }) {
    // Dismiss any existing messages before showing a new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white),
            if (icon != null) const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showMessage(
      context,
      message,
      color: Colors.green,
      icon: Icons.check_circle_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    showMessage(
      context,
      message,
      color: Colors.orange,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    showMessage(context, message, color: Colors.red, icon: Icons.error_outline);
  }
}
