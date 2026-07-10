import 'package:logger/logger.dart' as pkg_logger;

import '../config/app_config.dart';

/// Application-wide logging service.
///
/// Wraps the `logger` package with application-specific log levels
/// and formatting. All logging throughout the application should
/// use this service.
class AppLogger {
  /// Creates an [AppLogger] with the specified minimum log level.
  AppLogger({LogLevel minLevel = LogLevel.info})
      : _logger = pkg_logger.Logger(
          filter: _AppLogFilter(minLevel),
          printer: pkg_logger.PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 80,
            noBoxingByDefault: true,
          ),
        );

  final pkg_logger.Logger _logger;

  /// Logs a debug message.
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Logs an informational message.
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a warning message.
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Logs an error message.
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a fatal/critical message.
  void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

class _AppLogFilter extends pkg_logger.LogFilter {
  _AppLogFilter(this._minLevel);

  final LogLevel _minLevel;

  @override
  bool shouldLog(pkg_logger.LogEvent event) {
    final eventLevel = _mapLevel(event.level);
    return eventLevel.index >= _minLevel.index;
  }

  LogLevel _mapLevel(pkg_logger.Level level) {
    return switch (level) {
      pkg_logger.Level.debug || pkg_logger.Level.trace => LogLevel.debug,
      pkg_logger.Level.info => LogLevel.info,
      pkg_logger.Level.warning => LogLevel.warning,
      pkg_logger.Level.error => LogLevel.error,
      pkg_logger.Level.fatal => LogLevel.fatal,
      _ => LogLevel.debug,
    };
  }
}
