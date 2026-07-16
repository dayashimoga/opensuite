/// FileUtility Core Package
///
/// Provides foundational services including dependency injection,
/// logging, error handling, configuration management, and feature flags.
export 'src/config/app_config.dart';
export 'src/config/environment.dart';
export 'src/config/feature_flags.dart';
export 'src/constants/app_constants.dart';
export 'src/di/service_locator.dart';
export 'src/errors/app_error.dart';
export 'src/errors/error_handler.dart';
export 'src/errors/result.dart';
export 'src/formulas/formula_engine.dart';
export 'src/logging/app_logger.dart';
export 'src/models/document_metadata.dart';
export 'src/models/file_type.dart';
export 'src/models/presentation_models.dart';
export 'src/models/spreadsheet_models.dart';
export 'src/shortcuts/keyboard_shortcut_service.dart';
export 'src/utils/date_utils.dart';
export 'src/utils/file_utils.dart';
export 'src/utils/input_sanitizer.dart';
export 'src/utils/clipboard_service.dart';
export 'src/utils/string_utils.dart';
export 'src/utils/undo_redo_manager.dart';
export 'src/utils/line_prefix_utils.dart';
export 'src/utils/file_download_utils.dart';

// --- Sprint 1: Shared Services ---
export 'src/services/save_manager.dart';
export 'src/services/export_manager.dart';
export 'src/services/import_manager.dart';
export 'src/services/background_task_manager.dart';
export 'src/services/file_format_registry.dart';
export 'src/services/context_menu_builder.dart';

// --- Formats ---
export 'src/formats/csv_codec.dart';

// --- Imaging ---
export 'src/imaging/image_processor.dart';
