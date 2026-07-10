/// Feature flags for controlling feature availability at runtime.
///
/// Features can be toggled without redeploying the application.
/// This enables gradual rollouts and A/B testing.
class FeatureFlags {
  /// Creates a [FeatureFlags] instance with all features specified.
  const FeatureFlags({
    this.enableNotes = true,
    this.enableFileManager = true,
    this.enableTextEditor = true,
    this.enableDocumentEditor = false,
    this.enableSpreadsheet = false,
    this.enablePresentation = false,
    this.enablePdfViewer = false,
    this.enableImageEditor = false,
    this.enableCloudSync = false,
    this.enableVersionHistory = false,
    this.enableCollaboration = false,
    this.enableSpellCheck = false,
  });

  /// Creates default flags with all Sprint 1 features enabled.
  factory FeatureFlags.sprint1() {
    return const FeatureFlags(
      enableNotes: true,
      enableFileManager: true,
      enableTextEditor: true,
    );
  }

  /// Creates flags with all features enabled (for testing).
  factory FeatureFlags.allEnabled() {
    return const FeatureFlags(
      enableNotes: true,
      enableFileManager: true,
      enableTextEditor: true,
      enableDocumentEditor: true,
      enableSpreadsheet: true,
      enablePresentation: true,
      enablePdfViewer: true,
      enableImageEditor: true,
      enableCloudSync: true,
      enableVersionHistory: true,
      enableCollaboration: true,
      enableSpellCheck: true,
    );
  }

  /// Whether the Notes module is available.
  final bool enableNotes;

  /// Whether the File Manager module is available.
  final bool enableFileManager;

  /// Whether the Text/Markdown Editor module is available.
  final bool enableTextEditor;

  /// Whether the Document Editor (DOCX/ODT/RTF) module is available.
  final bool enableDocumentEditor;

  /// Whether the Spreadsheet module is available.
  final bool enableSpreadsheet;

  /// Whether the Presentation module is available.
  final bool enablePresentation;

  /// Whether the PDF Viewer/Editor module is available.
  final bool enablePdfViewer;

  /// Whether the Image Editor module is available.
  final bool enableImageEditor;

  /// Whether cloud sync is available.
  final bool enableCloudSync;

  /// Whether version history is available.
  final bool enableVersionHistory;

  /// Whether real-time collaboration is available.
  final bool enableCollaboration;

  /// Whether spell checking is available.
  final bool enableSpellCheck;

  /// Returns a copy with the specified flags overridden.
  FeatureFlags copyWith({
    bool? enableNotes,
    bool? enableFileManager,
    bool? enableTextEditor,
    bool? enableDocumentEditor,
    bool? enableSpreadsheet,
    bool? enablePresentation,
    bool? enablePdfViewer,
    bool? enableImageEditor,
    bool? enableCloudSync,
    bool? enableVersionHistory,
    bool? enableCollaboration,
    bool? enableSpellCheck,
  }) {
    return FeatureFlags(
      enableNotes: enableNotes ?? this.enableNotes,
      enableFileManager: enableFileManager ?? this.enableFileManager,
      enableTextEditor: enableTextEditor ?? this.enableTextEditor,
      enableDocumentEditor: enableDocumentEditor ?? this.enableDocumentEditor,
      enableSpreadsheet: enableSpreadsheet ?? this.enableSpreadsheet,
      enablePresentation: enablePresentation ?? this.enablePresentation,
      enablePdfViewer: enablePdfViewer ?? this.enablePdfViewer,
      enableImageEditor: enableImageEditor ?? this.enableImageEditor,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      enableVersionHistory: enableVersionHistory ?? this.enableVersionHistory,
      enableCollaboration: enableCollaboration ?? this.enableCollaboration,
      enableSpellCheck: enableSpellCheck ?? this.enableSpellCheck,
    );
  }
}
