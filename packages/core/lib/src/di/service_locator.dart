import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../config/feature_flags.dart';
import '../logging/app_logger.dart';
import '../errors/error_handler.dart';

/// Global service locator instance.
///
/// All application services are registered here and can be resolved
/// from anywhere in the app. Use [setupServiceLocator] to initialize.
final GetIt serviceLocator = GetIt.instance;

/// Convenience alias for [serviceLocator].
GetIt get sl => serviceLocator;

/// Initializes the service locator with core services.
///
/// Must be called once at application startup. Registers:
/// - [AppConfig] — application configuration
/// - [FeatureFlags] — feature toggles
/// - [AppLogger] — logging service
/// - [ErrorHandler] — error handling service
///
/// Module-specific services should be registered separately
/// using [registerModuleServices].
Future<void> setupServiceLocator({
  required AppConfig config,
  FeatureFlags? featureFlags,
}) async {
  // Configuration
  serviceLocator.registerSingleton<AppConfig>(config);
  serviceLocator.registerSingleton<FeatureFlags>(
    featureFlags ?? FeatureFlags.sprint1(),
  );

  // Logging
  serviceLocator.registerSingleton<AppLogger>(
    AppLogger(minLevel: config.logLevel),
  );

  // Error handling
  serviceLocator.registerSingleton<ErrorHandler>(
    ErrorHandler(logger: serviceLocator<AppLogger>()),
  );
}

/// Resets the service locator (primarily for testing).
Future<void> resetServiceLocator() async {
  await serviceLocator.reset();
}
