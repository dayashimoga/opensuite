/// Application string resources.
///
/// Centralized string resources for the application UI.
/// In a full l10n setup, these would be generated from ARB files.
/// This implementation provides a simple, extensible foundation
/// that can be swapped to generated l10n when needed.
class AppLocalizations {
  const AppLocalizations._();

  // ── General ───────────────────────────────────────────────
  static const String appName = 'OpenSuite';
  static const String appDescription =
      'Open-source cross-platform Office & Productivity Suite';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String create = 'Create';
  static const String search = 'Search';
  static const String close = 'Close';
  static const String settings = 'Settings';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Retry';
  static const String noResults = 'No results found';
  static const String confirm = 'Confirm';
  static const String undo = 'Undo';
  static const String redo = 'Redo';

  // ── Navigation ────────────────────────────────────────────
  static const String home = 'Home';
  static const String notes = 'Notes';
  static const String fileManager = 'Files';
  static const String textEditor = 'Editor';
  static const String documents = 'Documents';
  static const String spreadsheets = 'Spreadsheets';
  static const String presentations = 'Presentations';
  static const String pdf = 'PDF';
  static const String images = 'Images';

  // ── Home ──────────────────────────────────────────────────
  static const String welcomeTitle = 'Welcome to OpenSuite';
  static const String welcomeDescription =
      'Your open-source productivity suite for documents, notes, and more.';
  static const String recentFiles = 'Recent Files';
  static const String quickActions = 'Quick Actions';
  static const String noRecentFiles = 'No recent files';
  static const String noRecentFilesDescription =
      'Files you open will appear here for quick access.';

  // ── Notes ─────────────────────────────────────────────────
  static const String newNote = 'New Note';
  static const String editNote = 'Edit Note';
  static const String deleteNote = 'Delete Note';
  static const String deleteNoteConfirm =
      'Are you sure you want to delete this note? This action cannot be undone.';
  static const String noNotes = 'No notes yet';
  static const String noNotesDescription =
      'Create your first note to get started.';
  static const String noteTitle = 'Title';
  static const String searchNotes = 'Search notes...';
  static const String pinNote = 'Pin Note';
  static const String unpinNote = 'Unpin Note';
  static const String favoriteNote = 'Favorite';
  static const String unfavoriteNote = 'Unfavorite';
  static const String plainText = 'Plain Text';
  static const String markdown = 'Markdown';
  static const String richText = 'Rich Text';
  static const String checklist = 'Checklist';

  // ── File Manager ──────────────────────────────────────────
  static const String browse = 'Browse';
  static const String favorites = 'Favorites';
  static const String rename = 'Rename';
  static const String copy = 'Copy';
  static const String move = 'Move';
  static const String deleteFile = 'Delete File';
  static const String deleteFileConfirm =
      'Are you sure you want to delete this file?';
  static const String fileDetails = 'File Details';
  static const String noFiles = 'No files';
  static const String noFilesDescription =
      'Open or import files to get started.';
  static const String importFile = 'Import File';
  static const String exportFile = 'Export File';
  static const String searchFiles = 'Search files...';

  // ── Text Editor ───────────────────────────────────────────
  static const String newDocument = 'New Document';
  static const String openDocument = 'Open Document';
  static const String saveDocument = 'Save Document';
  static const String untitled = 'Untitled';
  static const String wordCount = 'Words';
  static const String characterCount = 'Characters';
  static const String lineCount = 'Lines';
  static const String findAndReplace = 'Find & Replace';
  static const String findPlaceholder = 'Find...';
  static const String replacePlaceholder = 'Replace with...';
  static const String replaceAll = 'Replace All';
  static const String noDocuments = 'No documents';
  static const String noDocumentsDescription =
      'Create or open a document to start editing.';
  static const String preview = 'Preview';
  static const String autoSaved = 'Auto-saved';

  // ── Settings ──────────────────────────────────────────────
  static const String appearance = 'Appearance';
  static const String theme = 'Theme';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String language = 'Language';
  static const String editor = 'Editor';
  static const String fontSize = 'Font Size';
  static const String lineNumbers = 'Line Numbers';
  static const String wordWrap = 'Word Wrap';
  static const String autosave = 'Autosave';
  static const String autosaveInterval = 'Autosave Interval';
  static const String about = 'About';
  static const String version = 'Version';
  static const String licenses = 'Open Source Licenses';
  static const String storage = 'Storage';
  static const String clearData = 'Clear Data';
  static const String clearDataConfirm =
      'Are you sure you want to clear all data? This action cannot be undone.';
}
