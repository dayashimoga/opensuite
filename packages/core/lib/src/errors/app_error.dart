import 'package:equatable/equatable.dart';

/// Base class for all application errors.
///
/// Provides structured error information with error codes,
/// user-friendly messages, and optional stack traces.
class AppError extends Equatable implements Exception {
  /// Creates an [AppError] with the given parameters.
  const AppError({
    required this.code,
    required this.message,
    this.details,
    this.stackTrace,
  });

  /// Creates a generic unexpected error.
  factory AppError.unexpected([String? details]) {
    return AppError(
      code: ErrorCode.unexpected,
      message: 'An unexpected error occurred.',
      details: details,
    );
  }

  /// Creates a file not found error.
  factory AppError.fileNotFound(String path) {
    return AppError(
      code: ErrorCode.fileNotFound,
      message: 'File not found: $path',
      details: path,
    );
  }

  /// Creates a permission denied error.
  factory AppError.permissionDenied([String? resource]) {
    return AppError(
      code: ErrorCode.permissionDenied,
      message: 'Permission denied${resource != null ? ': $resource' : ''}.',
      details: resource,
    );
  }

  /// Creates a storage error.
  factory AppError.storage(String message, [String? details]) {
    return AppError(
      code: ErrorCode.storageError,
      message: message,
      details: details,
    );
  }

  /// Creates a validation error.
  factory AppError.validation(String message) {
    return AppError(
      code: ErrorCode.validationError,
      message: message,
    );
  }

  /// Creates a file format error.
  factory AppError.unsupportedFormat(String format) {
    return AppError(
      code: ErrorCode.unsupportedFormat,
      message: 'Unsupported file format: $format',
      details: format,
    );
  }

  /// Creates a file size exceeded error.
  factory AppError.fileTooLarge(int maxSizeBytes) {
    final maxSizeMb = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    return AppError(
      code: ErrorCode.fileTooLarge,
      message: 'File exceeds maximum size of ${maxSizeMb}MB.',
      details: maxSizeBytes.toString(),
    );
  }

  /// Machine-readable error code.
  final ErrorCode code;

  /// Human-readable error message suitable for display.
  final String message;

  /// Additional error details for debugging.
  final String? details;

  /// Stack trace at the point of error creation.
  @override
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [code, message, details];

  @override
  String toString() =>
      'AppError(code: ${code.name}, message: $message${details != null ? ', details: $details' : ''})';
}

/// Enumeration of all error codes in the application.
enum ErrorCode {
  /// An unexpected or unhandled error.
  unexpected,

  /// The requested file was not found.
  fileNotFound,

  /// Access to a resource was denied.
  permissionDenied,

  /// An error occurred during storage operations.
  storageError,

  /// Input validation failed.
  validationError,

  /// The file format is not supported.
  unsupportedFormat,

  /// The file exceeds the maximum allowed size.
  fileTooLarge,

  /// A network operation failed.
  networkError,

  /// An operation was cancelled by the user.
  cancelled,

  /// A timeout occurred waiting for an operation.
  timeout,

  /// Data could not be parsed or decoded.
  parseError,

  /// The operation conflicts with the current state.
  conflict,
}
