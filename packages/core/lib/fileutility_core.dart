/// FileUtility Core Package
///
/// Provides foundational services including dependency injection,
/// logging, error handling, configuration management, and feature flags.
library fileutility_core;

// Configuration
export 'src/config/app_config.dart';
export 'src/config/environment.dart';
export 'src/config/feature_flags.dart';

// Dependency Injection
export 'src/di/service_locator.dart';

// Error Handling
export 'src/errors/app_error.dart';
export 'src/errors/error_handler.dart';
export 'src/errors/result.dart';

// Logging
export 'src/logging/app_logger.dart';

// Models
export 'src/models/file_type.dart';
export 'src/models/document_metadata.dart';
export 'src/models/presentation_models.dart';
export 'src/models/spreadsheet_models.dart';

// Utils
export 'src/utils/date_utils.dart';
export 'src/utils/file_utils.dart';
export 'src/utils/string_utils.dart';
export 'src/utils/input_sanitizer.dart';

// Constants
export 'src/constants/app_constants.dart';

// Shortcuts
export 'src/shortcuts/keyboard_shortcut_service.dart';

// Formulas
export 'src/formulas/formula_engine.dart';
