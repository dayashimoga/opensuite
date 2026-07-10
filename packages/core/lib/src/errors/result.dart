import 'app_error.dart';

/// A discriminated union representing either a successful value or an error.
///
/// Use [Result] to handle operations that can fail without throwing exceptions.
///
/// ```dart
/// final result = await repository.getNote(id);
/// result.when(
///   success: (note) => print(note.title),
///   failure: (error) => print(error.message),
/// );
/// ```
sealed class Result<T> {
  const Result._();

  /// Creates a successful result with the given [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result with the given [error].
  const factory Result.failure(AppError error) = Failure<T>;

  /// Whether this result is a success.
  bool get isSuccess => this is Success<T>;

  /// Whether this result is a failure.
  bool get isFailure => this is Failure<T>;

  /// Returns the value if success, otherwise null.
  T? get valueOrNull {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>() => null,
    };
  }

  /// Returns the error if failure, otherwise null.
  AppError? get errorOrNull {
    return switch (this) {
      Success<T>() => null,
      Failure<T>(:final error) => error,
    };
  }

  /// Pattern matches on success or failure.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Failure<T>(:final error) => failure(error),
    };
  }

  /// Maps the success value to a new type.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => Result.success(transform(value)),
      Failure<T>(:final error) => Result.failure(error),
    };
  }

  /// Flat maps the success value to a new result.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => transform(value),
      Failure<T>(:final error) => Result.failure(error),
    };
  }
}

/// Represents a successful result containing a [value].
class Success<T> extends Result<T> {
  /// Creates a [Success] with the given [value].
  const Success(this.value) : super._();

  /// The successful value.
  final T value;
}

/// Represents a failed result containing an [error].
class Failure<T> extends Result<T> {
  /// Creates a [Failure] with the given [error].
  const Failure(this.error) : super._();

  /// The error that caused the failure.
  final AppError error;
}
