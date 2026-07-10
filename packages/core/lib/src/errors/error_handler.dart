import '../logging/app_logger.dart';
import 'app_error.dart';

/// Centralized error handler that logs and optionally reports errors.
///
/// All errors should flow through this handler to ensure consistent
/// logging and future crash reporting integration.
class ErrorHandler {
  /// Creates an [ErrorHandler] with the given logger.
  const ErrorHandler({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  /// Handles an [AppError] by logging it appropriately.
  ///
  /// Returns the same error for chaining.
  AppError handle(AppError error) {
    switch (error.code) {
      case ErrorCode.unexpected:
      case ErrorCode.storageError:
        _logger.error(
          error.message,
          error: error,
          stackTrace: error.stackTrace,
        );
      case ErrorCode.fileNotFound:
      case ErrorCode.unsupportedFormat:
      case ErrorCode.validationError:
      case ErrorCode.fileTooLarge:
        _logger.warning(error.message);
      case ErrorCode.permissionDenied:
        _logger.warning('Permission denied: ${error.details ?? 'unknown'}');
      case ErrorCode.networkError:
      case ErrorCode.timeout:
        _logger.warning('Network issue: ${error.message}');
      case ErrorCode.cancelled:
        _logger.info('Operation cancelled: ${error.message}');
      case ErrorCode.parseError:
      case ErrorCode.conflict:
        _logger.warning(error.message);
    }
    return error;
  }

  /// Handles a generic exception by wrapping it in an [AppError].
  AppError handleException(Object exception, [StackTrace? stackTrace]) {
    if (exception is AppError) {
      return handle(exception);
    }

    final error = AppError(
      code: ErrorCode.unexpected,
      message: exception.toString(),
      stackTrace: stackTrace,
    );

    return handle(error);
  }

  /// Executes a function and catches any errors, returning the result
  /// or the error through an [ErrorHandler].
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppError catch (e) {
      handle(e);
      rethrow;
    } catch (e, st) {
      final error = handleException(e, st);
      throw error;
    }
  }
}
