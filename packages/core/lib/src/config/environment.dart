import 'app_config.dart';

/// Manages environment-specific configuration.
///
/// Provides a centralized way to access and modify the current
/// application environment settings.
class EnvironmentConfig {
  EnvironmentConfig._();

  static AppConfig _config = AppConfig.development();

  /// The current application configuration.
  static AppConfig get current => _config;

  /// Initializes the environment configuration.
  ///
  /// Should be called once at application startup before any
  /// services are initialized.
  static void initialize(AppConfig config) {
    _config = config;
  }

  /// Returns the appropriate configuration for the given environment string.
  ///
  /// Falls back to development if the environment is not recognized.
  static AppConfig fromString(String environment) {
    switch (environment.toLowerCase()) {
      case 'production':
      case 'prod':
        return AppConfig.production();
      case 'development':
      case 'dev':
      default:
        return AppConfig.development();
    }
  }
}
