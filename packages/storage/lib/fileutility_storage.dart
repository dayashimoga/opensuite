/// FileUtility Storage Package
///
/// Provides offline-first storage abstractions including:
/// - SQLite database for structured data
/// - Key-value storage for preferences
/// - File storage for document content
library fileutility_storage;

// Database
export 'src/database/database_provider.dart';
export 'src/database/document_dao.dart';
export 'src/database/note_dao.dart';
export 'src/database/presentation_dao.dart';
export 'src/database/recent_file_dao.dart';
export 'src/database/spreadsheet_dao.dart';
export 'src/database/version_dao.dart';

// Key-Value Storage
export 'src/preferences/preferences_service.dart';

// File Storage
export 'src/file_storage/file_storage_service.dart';

// Models
export 'src/models/document_entity.dart';
export 'src/models/note_entity.dart';
export 'src/models/presentation_entity.dart';
export 'src/models/recent_file_entity.dart';
export 'src/models/spreadsheet_entity.dart';
export 'src/models/version_entity.dart';
