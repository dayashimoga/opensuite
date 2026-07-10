// Tests for InputSanitizer - runs independently of Flutter SDK
import 'package:fileutility_core/src/utils/input_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputSanitizer — XSS Prevention', () {
    test('removes script tags', () {
      final input = 'Hello<script>alert("xss")</script>World';
      final result = InputSanitizer.sanitizeHtml(input);
      expect(result, isNot(contains('<script')));
      expect(result, contains('Hello'));
      expect(result, contains('World'));
    });

    test('removes event handlers', () {
      final input = '<img src="x" onerror="alert(1)">';
      final result = InputSanitizer.sanitizeHtml(input);
      expect(result, isNot(contains('onerror=')));
    });

    test('removes javascript: URIs', () {
      final input = '<a href="javascript:alert(1)">click</a>';
      final result = InputSanitizer.sanitizeHtml(input);
      expect(result, isNot(contains('javascript:')));
    });

    test('encodeHtml escapes special characters', () {
      expect(InputSanitizer.encodeHtml('<b>'), equals('&lt;b&gt;'));
      expect(InputSanitizer.encodeHtml('"quotes"'), equals('&quot;quotes&quot;'));
      expect(InputSanitizer.encodeHtml('a&b'), equals('a&amp;b'));
    });
  });

  group('InputSanitizer — SQL Injection Prevention', () {
    test('escapes SQL LIKE wildcards in search', () {
      final result = InputSanitizer.sanitizeSearchQuery('100% complete');
      expect(result, contains(r'\%'));
    });

    test('escapes underscore wildcard', () {
      final result = InputSanitizer.sanitizeSearchQuery('user_name');
      expect(result, contains(r'\_'));
    });

    test('limits search query length', () {
      final longQuery = 'a' * 500;
      final result = InputSanitizer.sanitizeSearchQuery(longQuery);
      expect(result.length, lessThanOrEqualTo(InputSanitizer.maxSearchQueryLength));
    });
  });

  group('InputSanitizer — Path Traversal', () {
    test('rejects path traversal with ..', () {
      expect(InputSanitizer.sanitizeFilePath('../etc/passwd'), isNull);
      expect(InputSanitizer.sanitizeFilePath('dir/../../secret'), isNull);
    });

    test('rejects absolute paths', () {
      expect(InputSanitizer.sanitizeFilePath('/etc/passwd'), isNull);
      expect(InputSanitizer.sanitizeFilePath('C:\\Windows'), isNull);
    });

    test('rejects null bytes', () {
      expect(InputSanitizer.sanitizeFilePath('file\x00.txt'), isNull);
    });

    test('allows safe relative paths', () {
      expect(InputSanitizer.sanitizeFilePath('docs/file.txt'), equals('docs/file.txt'));
    });
  });

  group('InputSanitizer — File Name Validation', () {
    test('rejects empty names', () {
      expect(InputSanitizer.isFileNameSafe(''), isFalse);
    });

    test('rejects Windows reserved names', () {
      expect(InputSanitizer.isFileNameSafe('CON'), isFalse);
      expect(InputSanitizer.isFileNameSafe('PRN.txt'), isFalse);
      expect(InputSanitizer.isFileNameSafe('NUL'), isFalse);
      expect(InputSanitizer.isFileNameSafe('COM1'), isFalse);
    });

    test('rejects names with path separators', () {
      expect(InputSanitizer.isFileNameSafe('dir/file'), isFalse);
      expect(InputSanitizer.isFileNameSafe(r'dir\file'), isFalse);
    });

    test('accepts valid file names', () {
      expect(InputSanitizer.isFileNameSafe('document.txt'), isTrue);
      expect(InputSanitizer.isFileNameSafe('my-file_v2 (1).md'), isTrue);
    });
  });

  group('InputSanitizer — Content Validation', () {
    test('sanitizeTitle removes control characters', () {
      final result = InputSanitizer.sanitizeTitle('Hello\x00World\x1F!');
      expect(result, equals('HelloWorld!'));
    });

    test('sanitizeContent removes null bytes', () {
      final result = InputSanitizer.sanitizeContent('Hello\x00World');
      expect(result, equals('HelloWorld'));
    });

    test('isContentSizeValid enforces limits', () {
      expect(InputSanitizer.isContentSizeValid('Hello'), isTrue);
    });
  });
}
