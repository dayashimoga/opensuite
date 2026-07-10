import 'package:intl/intl.dart';

/// Date and time utility functions.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _fullDateFormat = DateFormat('MMM d, yyyy h:mm a');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd\'T\'HH:mm:ss');

  /// Formats a DateTime to a full date-time string (e.g., "Jul 8, 2026 3:30 PM").
  static String formatFull(DateTime dateTime) {
    return _fullDateFormat.format(dateTime);
  }

  /// Formats a DateTime to a short date string (e.g., "Jul 8, 2026").
  static String formatShort(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  /// Formats a DateTime to a time-only string (e.g., "3:30 PM").
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Formats a DateTime to ISO 8601 string.
  static String formatIso(DateTime dateTime) {
    return _isoFormat.format(dateTime);
  }

  /// Returns a human-readable relative time string.
  ///
  /// Examples: "just now", "5 minutes ago", "2 hours ago", "yesterday", "Jul 5, 2026"
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inDays == 1) {
      return 'yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return formatShort(dateTime);
  }
}
