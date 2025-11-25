// Placeholder for the file at: lib/widgets/profile_avatar.dart

import 'package:flutter/material.dart';
import 'dart:io';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;

  const ProfileAvatar({super.key, this.photoUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    Widget? childWidget;

    if (photoUrl != null) {
      // 1. Check if it's a local file path (e.g., from ImagePicker)
      // Local file paths do not start with a schema like 'http' or 'https'
      final bool isLocalFile = !photoUrl!.startsWith('http');

      if (isLocalFile) {
        // Use FileImage for local device files
        imageProvider = FileImage(File(photoUrl!));
      } else {
        // Use NetworkImage for server URLs
        imageProvider = NetworkImage(photoUrl!);
      }
    }

    if (imageProvider == null) {
      // Fallback for null or invalid URL
      childWidget = Icon(
        Icons.person,
        size: radius,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(
        (255 * 0.15).round(),
      ), // Light background for contrast
      backgroundImage: imageProvider,
      child: childWidget,
    );
  }
}
