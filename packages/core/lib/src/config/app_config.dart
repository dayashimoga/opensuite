/// Application configuration providing environment-aware settings.
class AppConfig {
  /// Creates an [AppConfig] instance.
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.appVersion,
    this.databaseName = 'fileutility.db',
    this.maxRecentFiles = 50,
    this.autosaveIntervalSeconds = 30,
    this.maxFileSizeBytes = 104857600, // 100MB
    this.enableAnalytics = false,
    this.enableCrashReporting = false,
    this.logLevel = LogLevel.info,
  });

  /// Creates a default development configuration.
  factory AppConfig.development() {
    return const AppConfig(
      environment: Environment.development,
      appName: 'FileUtility Dev',
      appVersion: '1.0.0',
      logLevel: LogLevel.debug,
    );
  }

  /// Creates a default production configuration.
  factory AppConfig.production() {
    return const AppConfig(
      environment: Environment.production,
      appName: 'FileUtility',
      appVersion: '1.0.0',
      enableAnalytics: true,
      enableCrashReporting: true,
      logLevel: LogLevel.warning,
    );
  }

  /// The current environment.
  final Environment environment;

  /// Application display name.
  final String appName;

  /// Application version string.
  final String appVersion;

  /// Database file name.
  final String databaseName;

  /// Maximum number of recent files to track.
  final int maxRecentFiles;

  /// Autosave interval in seconds.
  final int autosaveIntervalSeconds;

  /// Maximum file size in bytes.
  final int maxFileSizeBytes;

  /// Whether analytics collection is enabled.
  final bool enableAnalytics;

  /// Whether crash reporting is enabled.
  final bool enableCrashReporting;

  /// Minimum log level to output.
  final LogLevel logLevel;

  /// Whether the current environment is development.
  bool get isDevelopment => environment == Environment.development;

  /// Whether the current environment is production.
  bool get isProduction => environment == Environment.production;
}

/// Application runtime environment.
enum Environment {
  /// Development environment with debug features enabled.
  development,

  /// Staging environment for pre-release testing.
  staging,

  /// Production environment with optimized settings.
  production,
}

/// Log severity levels.
enum LogLevel {
  /// Verbose debugging information.
  debug,

  /// General informational messages.
  info,

  /// Potential issues that are not errors.
  warning,

  /// Errors that need attention.
  error,

  /// Critical errors that may cause data loss.
  fatal,
}
