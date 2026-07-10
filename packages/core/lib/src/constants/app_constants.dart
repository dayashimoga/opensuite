/// Application-wide constants.
///
/// All magic numbers and hardcoded strings are centralized here
/// to ensure consistency and easy modification.
class AppConstants {
  AppConstants._();

  // ── Application ──────────────────────────────────────────
  /// Application name.
  static const String appName = 'OpenSuite';

  /// Application version.
  static const String appVersion = '1.0.0';

  /// Application description.
  static const String appDescription =
      'Open-source cross-platform Office & Productivity Suite';

  /// Application repository URL.
  static const String repositoryUrl =
      'https://github.com/user/opensuite';

  /// Application license.
  static const String license = 'MIT';

  // ── Storage ──────────────────────────────────────────────
  /// Default database file name.
  static const String databaseName = 'fileutility.db';

  /// Maximum number of recent files to track.
  static const int maxRecentFiles = 50;

  /// Maximum undo history steps.
  static const int maxUndoSteps = 100;

  // ── UI ───────────────────────────────────────────────────
  /// Default animation duration in milliseconds.
  static const int animationDurationMs = 300;

  /// Sidebar width on desktop.
  static const double sidebarWidth = 280.0;

  /// Sidebar collapsed width.
  static const double sidebarCollapsedWidth = 72.0;

  /// Minimum width to show desktop layout.
  static const double desktopBreakpoint = 1024.0;

  /// Minimum width to show tablet layout.
  static const double tabletBreakpoint = 600.0;

  /// Maximum content width for readability.
  static const double maxContentWidth = 1200.0;

  // ── Editor ───────────────────────────────────────────────
  /// Default autosave interval in seconds.
  static const int autosaveIntervalSeconds = 30;

  /// Maximum file size in bytes (100MB).
  static const int maxFileSizeBytes = 104857600;

  /// Default tab size in spaces.
  static const int defaultTabSize = 4;

  // ── Search ───────────────────────────────────────────────
  /// Debounce duration for search input in milliseconds.
  static const int searchDebounceMs = 300;

  /// Maximum search results to display.
  static const int maxSearchResults = 100;
}
