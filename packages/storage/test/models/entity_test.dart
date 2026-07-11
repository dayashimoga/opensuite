import 'package:flutter_test/flutter_test.dart';
import 'package:fileutility_storage/fileutility_storage.dart';

void main() {
  group('NoteEntity', () {
    final now = DateTime(2026, 7, 1, 12, 0, 0);

    test('fromMap creates entity correctly', () {
      final map = {
        'id': 'note-1',
        'title': 'Test Note',
        'content': 'Hello world',
        'content_type': 'plain',
        'is_pinned': 1,
        'is_favorite': 0,
        'color': '#FF0000',
        'tags': 'work,personal',
        'created_at': now.toIso8601String(),
        'modified_at': now.toIso8601String(),
      };

      final entity = NoteEntity.fromMap(map);

      expect(entity.id, 'note-1');
      expect(entity.title, 'Test Note');
      expect(entity.content, 'Hello world');
      expect(entity.contentType, NoteContentType.plain);
      expect(entity.isPinned, true);
      expect(entity.isFavorite, false);
      expect(entity.color, '#FF0000');
      expect(entity.tags, ['work', 'personal']);
      expect(entity.createdAt, now);
      expect(entity.modifiedAt, now);
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'id': 'note-2',
        'title': null,
        'content': null,
        'content_type': null,
        'is_pinned': null,
        'is_favorite': null,
        'color': null,
        'tags': null,
        'created_at': now.toIso8601String(),
        'modified_at': now.toIso8601String(),
      };

      final entity = NoteEntity.fromMap(map);

      expect(entity.title, '');
      expect(entity.content, '');
      expect(entity.contentType, NoteContentType.plain);
      expect(entity.isPinned, false);
      expect(entity.isFavorite, false);
      expect(entity.color, isNull);
      expect(entity.tags, isEmpty);
    });

    test('toMap converts entity correctly', () {
      final entity = NoteEntity(
        id: 'note-1',
        title: 'Test',
        content: 'Content',
        contentType: NoteContentType.markdown,
        isPinned: true,
        isFavorite: true,
        color: '#00FF00',
        tags: const ['tag1', 'tag2'],
        createdAt: now,
        modifiedAt: now,
      );

      final map = entity.toMap();

      expect(map['id'], 'note-1');
      expect(map['title'], 'Test');
      expect(map['content'], 'Content');
      expect(map['content_type'], 'markdown');
      expect(map['is_pinned'], 1);
      expect(map['is_favorite'], 1);
      expect(map['color'], '#00FF00');
      expect(map['tags'], 'tag1,tag2');
      expect(map['created_at'], now.toIso8601String());
    });

    test('toMap/fromMap roundtrip preserves data', () {
      final original = NoteEntity(
        id: 'rt-1',
        title: 'Roundtrip',
        content: 'Data integrity',
        contentType: NoteContentType.richText,
        isPinned: true,
        isFavorite: true,
        color: '#AABBCC',
        tags: const ['a', 'b', 'c'],
        createdAt: now,
        modifiedAt: now,
      );

      final restored = NoteEntity.fromMap(original.toMap());

      expect(restored, equals(original));
    });

    test('copyWith overrides specified fields only', () {
      final entity = NoteEntity(
        id: 'note-1',
        title: 'Original',
        content: 'Content',
        contentType: NoteContentType.plain,
        createdAt: now,
        modifiedAt: now,
      );

      final copy = entity.copyWith(title: 'Modified', isPinned: true);

      expect(copy.id, 'note-1');
      expect(copy.title, 'Modified');
      expect(copy.content, 'Content');
      expect(copy.isPinned, true);
      expect(copy.isFavorite, false);
    });

    test('contentPreview returns truncated content', () {
      final entity = NoteEntity(
        id: '1',
        title: '',
        content: 'A' * 200,
        contentType: NoteContentType.plain,
        createdAt: now,
        modifiedAt: now,
      );

      expect(entity.contentPreview.length, lessThanOrEqualTo(102));
      expect(entity.contentPreview, endsWith('…'));
    });

    test('contentPreview returns "Empty note" for empty content', () {
      final entity = NoteEntity(
        id: '1',
        title: '',
        content: '',
        contentType: NoteContentType.plain,
        createdAt: now,
        modifiedAt: now,
      );

      expect(entity.contentPreview, 'Empty note');
    });

    test('contentPreview replaces newlines with spaces', () {
      final entity = NoteEntity(
        id: '1',
        title: '',
        content: 'Line 1\nLine 2\nLine 3',
        contentType: NoteContentType.plain,
        createdAt: now,
        modifiedAt: now,
      );

      expect(entity.contentPreview, 'Line 1 Line 2 Line 3');
    });

    test('equality works correctly', () {
      final a = NoteEntity(
        id: '1',
        title: 'A',
        content: '',
        contentType: NoteContentType.plain,
        createdAt: now,
        modifiedAt: now,
      );
      final b = NoteEntity(
        id: '1',
        title: 'A',
        content: '',
        contentType: NoteContentType.plain,
        createdAt: now,
        modifiedAt: now,
      );
      final c = a.copyWith(title: 'C');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('NoteContentType', () {
    test('fromString parses known values', () {
      expect(NoteContentType.fromString('plain'), NoteContentType.plain);
      expect(NoteContentType.fromString('markdown'), NoteContentType.markdown);
      expect(NoteContentType.fromString('rich_text'), NoteContentType.richText);
      expect(
          NoteContentType.fromString('checklist'), NoteContentType.checklist);
    });

    test('fromString defaults to plain for unknown values', () {
      expect(NoteContentType.fromString('unknown'), NoteContentType.plain);
      expect(NoteContentType.fromString(''), NoteContentType.plain);
    });

    test('value property returns correct string', () {
      expect(NoteContentType.plain.value, 'plain');
      expect(NoteContentType.markdown.value, 'markdown');
      expect(NoteContentType.richText.value, 'rich_text');
      expect(NoteContentType.checklist.value, 'checklist');
    });

    test('label property returns human-readable text', () {
      expect(NoteContentType.plain.label, 'Plain Text');
      expect(NoteContentType.markdown.label, 'Markdown');
      expect(NoteContentType.richText.label, 'Rich Text');
      expect(NoteContentType.checklist.label, 'Checklist');
    });
  });

  group('RecentFileEntity', () {
    final now = DateTime(2026, 7, 1);

    test('fromMap creates entity correctly', () {
      final map = {
        'id': 'file-1',
        'file_name': 'report.pdf',
        'file_path': '/docs/report.pdf',
        'file_type': 'pdf',
        'size_bytes': 2048,
        'is_favorite': 1,
        'last_opened_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
      };

      final entity = RecentFileEntity.fromMap(map);

      expect(entity.id, 'file-1');
      expect(entity.fileName, 'report.pdf');
      expect(entity.filePath, '/docs/report.pdf');
      expect(entity.fileType, 'pdf');
      expect(entity.sizeBytes, 2048);
      expect(entity.isFavorite, true);
    });

    test('toMap converts entity correctly', () {
      final entity = RecentFileEntity(
        id: 'file-1',
        fileName: 'doc.txt',
        filePath: '/doc.txt',
        fileType: 'text',
        sizeBytes: 512,
        isFavorite: false,
        lastOpenedAt: now,
        createdAt: now,
      );

      final map = entity.toMap();

      expect(map['id'], 'file-1');
      expect(map['file_name'], 'doc.txt');
      expect(map['file_path'], '/doc.txt');
      expect(map['file_type'], 'text');
      expect(map['size_bytes'], 512);
      expect(map['is_favorite'], 0);
    });

    test('toMap/fromMap roundtrip preserves data', () {
      final original = RecentFileEntity(
        id: 'rt-1',
        fileName: 'test.pdf',
        filePath: '/test.pdf',
        fileType: 'pdf',
        sizeBytes: 1024,
        lastOpenedAt: now,
        createdAt: now,
      );

      final restored = RecentFileEntity.fromMap(original.toMap());

      expect(restored, equals(original));
    });

    test('copyWith overrides specified fields', () {
      final entity = RecentFileEntity(
        id: 'file-1',
        fileName: 'old.pdf',
        filePath: '/old.pdf',
        fileType: 'pdf',
        lastOpenedAt: now,
        createdAt: now,
      );

      final copy = entity.copyWith(
        fileName: 'new.pdf',
        isFavorite: true,
      );

      expect(copy.id, 'file-1');
      expect(copy.fileName, 'new.pdf');
      expect(copy.isFavorite, true);
      expect(copy.filePath, '/old.pdf');
    });
  });
}
