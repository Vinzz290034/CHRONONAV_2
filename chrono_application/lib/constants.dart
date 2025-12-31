// chrono_application/lib/constants.dart

// --- Platform Channel Names ---

/// The channel used for one-off commands (Dart -> Native),
/// like start and stop positioning.
const String METHOD_CHANNEL_NAME = 'com.chronosnav/navigation';

/// The channel used for streaming real-time location data
/// (Native -> Dart).
const String EVENT_CHANNEL_NAME = 'com.chronosnav/location_stream';

// --- Other Constants ---
const String DEFAULT_FLOOR_ID = 'level1';
