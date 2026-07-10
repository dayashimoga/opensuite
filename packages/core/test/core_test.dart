import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileType', () {
    test('detects text files from path', () {
      expect(FileType.fromPath('document.txt'), FileType.text);
      expect(FileType.fromPath('notes.TXT'), FileType.text);
    });

    test('detects markdown files from path', () {
      expect(FileType.fromPath('readme.md'), FileType.markdown);
      expect(FileType.fromPath('docs.markdown'), FileType.markdown);
    });

    test('detects DOCX files from path', () {
      expect(FileType.fromPath('report.docx'), FileType.docx);
    });

    test('detects XLSX files from path', () {
      expect(FileType.fromPath('data.xlsx'), FileType.xlsx);
    });

    test('detects PDF files from path', () {
      expect(FileType.fromPath('invoice.pdf'), FileType.pdf);
    });

    test('detects image files from path', () {
      expect(FileType.fromPath('photo.jpg'), FileType.jpeg);
      expect(FileType.fromPath('logo.png'), FileType.png);
      expect(FileType.fromPath('icon.svg'), FileType.svg);
    });

    test('returns unknown for unrecognized extensions', () {
      expect(FileType.fromPath('file.xyz'), FileType.unknown);
      expect(FileType.fromPath('noextension'), FileType.unknown);
    });

    test('detects from MIME type', () {
      expect(FileType.fromMimeType('text/plain'), FileType.text);
      expect(FileType.fromMimeType('application/pdf'), FileType.pdf);
      expect(FileType.fromMimeType('image/png'), FileType.png);
      expect(FileType.fromMimeType('unknown/type'), FileType.unknown);
    });

    test('category checks work correctly', () {
      expect(FileType.text.isDocument, isTrue);
      expect(FileType.markdown.isDocument, isTrue);
      expect(FileType.xlsx.isSpreadsheet, isTrue);
      expect(FileType.pptx.isPresentation, isTrue);
      expect(FileType.jpeg.isImage, isTrue);
      expect(FileType.pdf.isDocument, isFalse);
    });

    test('primaryExtension returns first extension', () {
      expect(FileType.text.primaryExtension, '.txt');
      expect(FileType.markdown.primaryExtension, '.md');
      expect(FileType.unknown.primaryExtension, '');
    });
  });

  group('Result', () {
    test('Success contains value', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.errorOrNull, isNull);
    });

    test('Failure contains error', () {
      final error = AppError.unexpected('test error');
      final result = Result<int>.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, error);
    });

    test('when pattern matches correctly', () {
      const success = Result<int>.success(42);
      final failure = Result<int>.failure(AppError.unexpected());

      final successValue = success.when(
        success: (v) => 'got $v',
        failure: (e) => 'error',
      );
      expect(successValue, 'got 42');

      final failureValue = failure.when(
        success: (v) => 'got $v',
        failure: (e) => 'error: ${e.message}',
      );
      expect(failureValue, contains('error'));
    });

    test('map transforms success value', () {
      const result = Result<int>.success(21);
      final mapped = result.map((v) => v * 2);

      expect(mapped.valueOrNull, 42);
    });

    test('map preserves failure', () {
      final error = AppError.unexpected();
      final result = Result<int>.failure(error);
      final mapped = result.map((v) => v * 2);

      expect(mapped.isFailure, isTrue);
    });

    test('flatMap chains operations', () {
      const result = Result<int>.success(42);
      final chained = result.flatMap(
        (v) => Result<String>.success('value: $v'),
      );

      expect(chained.valueOrNull, 'value: 42');
    });
  });

  group('StringUtils', () {
    test('truncate shortens long strings', () {
      expect(StringUtils.truncate('Hello World', 5), 'Hell…');
      expect(StringUtils.truncate('Hi', 5), 'Hi');
    });

    test('capitalize first letter', () {
      expect(StringUtils.capitalize('hello'), 'Hello');
      expect(StringUtils.capitalize(''), '');
    });

    test('wordCount counts words', () {
      expect(StringUtils.wordCount('hello world'), 2);
      expect(StringUtils.wordCount('  hello   world  '), 2);
      expect(StringUtils.wordCount(''), 0);
      expect(StringUtils.wordCount('   '), 0);
    });

    test('isBlank checks empty/whitespace', () {
      expect(StringUtils.isBlank(null), isTrue);
      expect(StringUtils.isBlank(''), isTrue);
      expect(StringUtils.isBlank('  '), isTrue);
      expect(StringUtils.isBlank('hello'), isFalse);
    });

    test('slugify creates URL-safe strings', () {
      expect(StringUtils.slugify('Hello World!'), 'hello-world');
      expect(StringUtils.slugify('My Document 2024'), 'my-document-2024');
    });
  });

  group('FileUtils', () {
    test('getExtension returns lowercase extension', () {
      expect(FileUtils.getExtension('doc.TXT'), '.txt');
      expect(FileUtils.getExtension('file.md'), '.md');
    });

    test('getBaseName returns name without extension', () {
      expect(FileUtils.getBaseName('document.txt'), 'document');
    });

    test('getFileName returns full filename', () {
      expect(FileUtils.getFileName('/path/to/document.txt'), 'document.txt');
    });

    test('isValidFileName rejects invalid names', () {
      expect(FileUtils.isValidFileName(''), isFalse);
      expect(FileUtils.isValidFileName('file<name'), isFalse);
      expect(FileUtils.isValidFileName('CON.txt'), isFalse);
      expect(FileUtils.isValidFileName('a' * 256), isFalse);
    });

    test('isValidFileName accepts valid names', () {
      expect(FileUtils.isValidFileName('document.txt'), isTrue);
      expect(FileUtils.isValidFileName('my-file_v2.md'), isTrue);
    });

    test('sanitizeFileName replaces invalid chars', () {
      expect(FileUtils.sanitizeFileName('file<name>'), 'file_name_');
      expect(FileUtils.sanitizeFileName('a:b'), 'a_b');
    });

    test('formatSize formats bytes to human-readable', () {
      expect(FileUtils.formatSize(500), '500 B');
      expect(FileUtils.formatSize(1024), '1.0 KB');
      expect(FileUtils.formatSize(1048576), '1.0 MB');
      expect(FileUtils.formatSize(1073741824), '1.0 GB');
    });

    test('generateUniqueName avoids conflicts', () {
      final existing = {'doc.txt', 'doc (1).txt'};
      expect(FileUtils.generateUniqueName('doc.txt', existing), 'doc (2).txt');
      expect(FileUtils.generateUniqueName('new.txt', existing), 'new.txt');
    });
  });

  group('AppConfig', () {
    test('development config has debug log level', () {
      final config = AppConfig.development();
      expect(config.isDevelopment, isTrue);
      expect(config.isProduction, isFalse);
      expect(config.logLevel, LogLevel.debug);
    });

    test('production config has warning log level', () {
      final config = AppConfig.production();
      expect(config.isProduction, isTrue);
      expect(config.isDevelopment, isFalse);
      expect(config.logLevel, LogLevel.warning);
    });
  });

  group('FeatureFlags', () {
    test('sprint1 enables core modules', () {
      final flags = FeatureFlags.sprint1();
      expect(flags.enableNotes, isTrue);
      expect(flags.enableFileManager, isTrue);
      expect(flags.enableTextEditor, isTrue);
      expect(flags.enableDocumentEditor, isFalse);
      expect(flags.enableSpreadsheet, isFalse);
    });

    test('allEnabled enables everything', () {
      final flags = FeatureFlags.allEnabled();
      expect(flags.enableNotes, isTrue);
      expect(flags.enableDocumentEditor, isTrue);
      expect(flags.enableSpreadsheet, isTrue);
      expect(flags.enablePdfViewer, isTrue);
    });

    test('copyWith overrides specific flags', () {
      final flags = FeatureFlags.sprint1();
      final updated = flags.copyWith(enableDocumentEditor: true);

      expect(updated.enableDocumentEditor, isTrue);
      expect(updated.enableNotes, isTrue); // unchanged
    });
  });

  group('AppError', () {
    test('unexpected error has correct code', () {
      final error = AppError.unexpected('details');
      expect(error.code, ErrorCode.unexpected);
      expect(error.details, 'details');
    });

    test('fileNotFound includes path', () {
      final error = AppError.fileNotFound('/path/to/file');
      expect(error.code, ErrorCode.fileNotFound);
      expect(error.message, contains('/path/to/file'));
    });

    test('fileTooLarge formats size', () {
      final error = AppError.fileTooLarge(104857600);
      expect(error.message, contains('100.0MB'));
    });

    test('toString includes code and message', () {
      final error = AppError.validation('bad input');
      expect(error.toString(), contains('validationError'));
      expect(error.toString(), contains('bad input'));
    });

    test('equality works via Equatable', () {
      final a = AppError.validation('test');
      final b = AppError.validation('test');
      expect(a, equals(b));
    });
  });

  group('DocumentMetadata', () {
    test('formattedSize returns human-readable string', () {
      final meta = DocumentMetadata(
        id: '1',
        title: 'Test',
        fileType: FileType.text,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        sizeBytes: 1048576,
      );
      expect(meta.formattedSize, '1.0 MB');
    });

    test('formattedSize returns Unknown when null', () {
      final meta = DocumentMetadata(
        id: '1',
        title: 'Test',
        fileType: FileType.text,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      expect(meta.formattedSize, 'Unknown');
    });

    test('copyWith creates modified copy', () {
      final meta = DocumentMetadata(
        id: '1',
        title: 'Original',
        fileType: FileType.text,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      final copy = meta.copyWith(title: 'Updated');

      expect(copy.title, 'Updated');
      expect(copy.id, '1'); // unchanged
    });
  });
}
