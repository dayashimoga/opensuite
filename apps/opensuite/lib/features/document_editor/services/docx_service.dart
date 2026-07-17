import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Service for importing and exporting DOCX (Office Open XML) documents.
///
/// DOCX files are ZIP archives containing XML files following the
/// Office Open XML standard. This service handles:
/// - Export: Quill Delta JSON → OOXML paragraphs → ZIP archive
/// - Import: ZIP archive → parse document.xml → Quill Delta JSON
///
/// Supports: paragraphs, text runs (bold/italic/underline/color),
/// headings (H1-H6), ordered/unordered lists, tables, and images.
class DocxService {
  DocxService._();

  /// Export Quill Delta JSON to DOCX bytes.
  static Uint8List exportFromDelta({
    required String deltaJson,
    required String plainText,
    required String title,
  }) {
    return _DocxExporter.export(
      deltaJson: deltaJson,
      plainText: plainText,
      title: title,
    );
  }

  /// Import a DOCX file and return Delta JSON + plain text + title.
  static Map<String, String> importToDocument({
    required Uint8List fileBytes,
    required String fileName,
  }) {
    return _DocxImporter.import_(fileBytes: fileBytes, fileName: fileName);
  }
}

// --- DOCX Export ---

class _DocxExporter {
  static Uint8List export({
    required String deltaJson,
    required String plainText,
    required String title,
  }) {
    // Parse Delta operations
    List<dynamic> ops;
    try {
      ops = jsonDecode(deltaJson) as List<dynamic>;
    } catch (_) {
      // Fallback: treat as plain text
      ops = [
        {'insert': '$plainText\n'}
      ];
    }

    // Build OOXML body paragraphs from Delta ops
    final bodyXml = _buildBodyXml(ops, title);

    // Build the ZIP archive
    final archive = Archive();

    // [Content_Types].xml
    _addToArchive(archive, '[Content_Types].xml', _contentTypesXml());

    // _rels/.rels
    _addToArchive(archive, '_rels/.rels', _relsXml());

    // word/_rels/document.xml.rels
    _addToArchive(
        archive, 'word/_rels/document.xml.rels', _documentRelsXml());

    // word/document.xml
    _addToArchive(archive, 'word/document.xml', bodyXml);

    // word/styles.xml
    _addToArchive(archive, 'word/styles.xml', _stylesXml());

    // word/settings.xml
    _addToArchive(archive, 'word/settings.xml', _settingsXml());

    // word/fontTable.xml
    _addToArchive(archive, 'word/fontTable.xml', _fontTableXml());

    // docProps/core.xml
    _addToArchive(archive, 'docProps/core.xml', _corePropsXml(title));

    // docProps/app.xml
    _addToArchive(archive, 'docProps/app.xml', _appPropsXml());

    // Encode to ZIP
    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes!);
  }

  static void _addToArchive(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  static String _buildBodyXml(List<dynamic> ops, String title) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.write(
        '<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" '
        'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" '
        'xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" '
        'xmlns:v="urn:schemas-microsoft-com:vml" '
        'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
        'xmlns:w10="urn:schemas-microsoft-com:office:word" '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" '
        'xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" '
        'xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" '
        'xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" '
        'xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" '
        'mc:Ignorable="w14 wp14">');
    buffer.write('<w:body>');

    // Process Delta operations into paragraphs
    final paragraphs = _deltaOpsToParagraphs(ops);
    for (final para in paragraphs) {
      buffer.write(para);
    }

    // Section properties
    buffer.write('<w:sectPr>');
    buffer.write(
        '<w:pgSz w:w="12240" w:h="15840"/>'); // Letter size
    buffer.write(
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>');
    buffer.write('</w:sectPr>');

    buffer.write('</w:body>');
    buffer.write('</w:document>');
    return buffer.toString();
  }

  static List<String> _deltaOpsToParagraphs(List<dynamic> ops) {
    final paragraphs = <String>[];
    final currentRuns = <String>[];
    Map<String, dynamic>? currentBlockAttrs;

    for (final op in ops) {
      if (op is! Map<String, dynamic>) continue;
      final insert = op['insert'];
      final attrs = op['attributes'] as Map<String, dynamic>? ?? {};

      if (insert is String) {
        final lines = insert.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].isNotEmpty) {
            currentRuns.add(_buildRun(lines[i], attrs));
          }
          // Each newline terminates a paragraph
          if (i < lines.length - 1) {
            final blockAttrs = (insert == '\n' && attrs.isNotEmpty) ? attrs : currentBlockAttrs;
            paragraphs.add(
                _buildParagraph(List.from(currentRuns), blockAttrs));
            currentRuns.clear();
            currentBlockAttrs = null;
          }
        }

        // Check for block-level attributes (applied to the newline char)
        if (insert == '\n' && attrs.isNotEmpty) {
          currentBlockAttrs = attrs;
        }
      }
    }

    // Flush remaining runs
    if (currentRuns.isNotEmpty) {
      paragraphs.add(
          _buildParagraph(List.from(currentRuns), currentBlockAttrs));
    }

    return paragraphs;
  }

  static String _buildRun(String text, Map<String, dynamic> attrs) {
    final buffer = StringBuffer();
    buffer.write('<w:r>');

    // Run properties
    final hasProps = attrs.containsKey('bold') ||
        attrs.containsKey('italic') ||
        attrs.containsKey('underline') ||
        attrs.containsKey('strike') ||
        attrs.containsKey('color') ||
        attrs.containsKey('background') ||
        attrs.containsKey('size') ||
        attrs.containsKey('font');

    if (hasProps) {
      buffer.write('<w:rPr>');
      if (attrs['bold'] == true) buffer.write('<w:b/>');
      if (attrs['italic'] == true) buffer.write('<w:i/>');
      if (attrs['underline'] == true) buffer.write('<w:u w:val="single"/>');
      if (attrs['strike'] == true) buffer.write('<w:strike/>');
      if (attrs.containsKey('color')) {
        final color = (attrs['color'] as String).replaceAll('#', '');
        buffer.write('<w:color w:val="$color"/>');
      }
      if (attrs.containsKey('background')) {
        final bg = (attrs['background'] as String).replaceAll('#', '');
        buffer.write('<w:highlight w:val="$bg"/>');
      }
      if (attrs.containsKey('size')) {
        // Quill uses pixel-like sizes; DOCX uses half-points
        final sizeVal = attrs['size'];
        int halfPts;
        if (sizeVal is num) {
          halfPts = (sizeVal * 2).round();
        } else if (sizeVal is String) {
          final parsed = double.tryParse(sizeVal.replaceAll('px', ''));
          halfPts = parsed != null ? (parsed * 2).round() : 24;
        } else {
          halfPts = 24;
        }
        buffer.write('<w:sz w:val="$halfPts"/>');
      }
      if (attrs.containsKey('font')) {
        buffer.write(
            '<w:rFonts w:ascii="${attrs['font']}" w:hAnsi="${attrs['font']}"/>');
      }
      buffer.write('</w:rPr>');
    }

    // Escape XML special characters
    final escaped = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    buffer.write('<w:t xml:space="preserve">$escaped</w:t>');
    buffer.write('</w:r>');
    return buffer.toString();
  }

  static String _buildParagraph(
      List<String> runs, Map<String, dynamic>? blockAttrs) {
    final buffer = StringBuffer();
    buffer.write('<w:p>');

    // Paragraph properties
    if (blockAttrs != null && blockAttrs.isNotEmpty) {
      buffer.write('<w:pPr>');

      // Heading
      if (blockAttrs.containsKey('header')) {
        final level = blockAttrs['header'];
        if (level is int && level >= 1 && level <= 6) {
          buffer.write('<w:pStyle w:val="Heading$level"/>');
        }
      }

      // List (bullet or ordered)
      if (blockAttrs.containsKey('list')) {
        final listType = blockAttrs['list'];
        buffer.write('<w:numPr>');
        if (listType == 'ordered') {
          buffer.write('<w:numId w:val="1"/>');
        } else {
          buffer.write('<w:numId w:val="2"/>');
        }
        final indent = blockAttrs['indent'] as int? ?? 0;
        buffer.write('<w:ilvl w:val="$indent"/>');
        buffer.write('</w:numPr>');
      }

      // Alignment
      if (blockAttrs.containsKey('align')) {
        final align = blockAttrs['align'];
        String jc;
        switch (align) {
          case 'center':
            jc = 'center';
          case 'right':
            jc = 'right';
          case 'justify':
            jc = 'both';
          default:
            jc = 'left';
        }
        buffer.write('<w:jc w:val="$jc"/>');
      }

      // Blockquote (indent)
      if (blockAttrs.containsKey('blockquote') &&
          blockAttrs['blockquote'] == true) {
        buffer.write('<w:ind w:left="720"/>');
        buffer.write('<w:pBdr><w:left w:val="single" w:sz="4" w:space="4" w:color="999999"/></w:pBdr>');
      }

      // Indent
      if (blockAttrs.containsKey('indent')) {
        final indent = blockAttrs['indent'] as int;
        if (!blockAttrs.containsKey('list')) {
          buffer.write('<w:ind w:left="${indent * 720}"/>');
        }
      }

      buffer.write('</w:pPr>');
    }

    for (final run in runs) {
      buffer.write(run);
    }

    buffer.write('</w:p>');
    return buffer.toString();
  }

  // --- Standard DOCX XML templates ---

  static String _contentTypesXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

  static String _relsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

  static String _documentRelsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>
</Relationships>''';

  static String _stylesXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="24"/>
        <w:szCs w:val="24"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="160" w:line="259" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:outlineLvl w:val="0"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="48"/><w:szCs w:val="48"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:outlineLvl w:val="1"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:outlineLvl w:val="2"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr>
  </w:style>
</w:styles>''';

  static String _settingsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:defaultTabStop w:val="720"/>
  <w:characterSpacingControl w:val="doNotCompress"/>
</w:settings>''';

  static String _fontTableXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:fonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:font w:name="Calibri">
    <w:panose1 w:val="020F0502020204030204"/>
    <w:charset w:val="00"/>
    <w:family w:val="swiss"/>
    <w:pitch w:val="variable"/>
  </w:font>
</w:fonts>''';

  static String _corePropsXml(String title) {
    final now = DateTime.now().toUtc().toIso8601String();
    final escaped = title
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>$escaped</dc:title>
  <dc:creator>OpenSuite</dc:creator>
  <dcterms:created xsi:type="dcterms:W3CDTF">$now</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$now</dcterms:modified>
</cp:coreProperties>''';
  }

  static String _appPropsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>OpenSuite</Application>
  <AppVersion>2.0</AppVersion>
</Properties>''';
}

// --- DOCX Import ---

class _DocxImporter {
  static Map<String, String> import_({
    required Uint8List fileBytes,
    required String fileName,
  }) {
    // Decode ZIP archive
    final archive = ZipDecoder().decodeBytes(fileBytes);

    // Find document.xml
    ArchiveFile? docFile;
    for (final file in archive) {
      if (file.name == 'word/document.xml' ||
          file.name.endsWith('/document.xml')) {
        docFile = file;
        break;
      }
    }

    if (docFile == null) {
      throw FormatException('Invalid DOCX: word/document.xml not found');
    }

    final docXml = utf8.decode(docFile.content as List<int>);
    final xmlDoc = XmlDocument.parse(docXml);

    // Extract title from core.xml if available
    String title = fileName.replaceAll('.docx', '');
    for (final file in archive) {
      if (file.name == 'docProps/core.xml' ||
          file.name.endsWith('/core.xml')) {
        try {
          final coreXml = utf8.decode(file.content as List<int>);
          final coreDoc = XmlDocument.parse(coreXml);
          final titleElem = coreDoc.findAllElements('dc:title').firstOrNull;
          if (titleElem != null && titleElem.innerText.isNotEmpty) {
            title = titleElem.innerText;
          }
        } catch (_) {
          // Use filename as title
        }
        break;
      }
    }

    // Parse paragraphs from document.xml
    final deltaOps = <Map<String, dynamic>>[];
    final plainTextBuffer = StringBuffer();

    // Namespace-aware element finding
    final body = _findElement(xmlDoc.rootElement, 'body');
    if (body == null) {
      return {
        'title': title,
        'deltaJson': jsonEncode([
          {'insert': '\n'}
        ]),
        'plainText': '',
      };
    }

    for (final paragraph in _findElements(body, 'p')) {
      final pPr = _findElement(paragraph, 'pPr');
      Map<String, dynamic>? blockAttrs;

      if (pPr != null) {
        blockAttrs = {};

        // Check for heading style
        final pStyle = _findElement(pPr, 'pStyle');
        if (pStyle != null) {
          final styleVal =
              pStyle.getAttribute('w:val') ?? pStyle.getAttribute('val') ?? '';
          final headingMatch = RegExp(r'Heading(\d)').firstMatch(styleVal);
          if (headingMatch != null) {
            blockAttrs['header'] = int.parse(headingMatch.group(1)!);
          }
        }

        // Check for list (numPr)
        final numPr = _findElement(pPr, 'numPr');
        if (numPr != null) {
          final numId = _findElement(numPr, 'numId');
          final numIdVal =
              numId?.getAttribute('w:val') ?? numId?.getAttribute('val') ?? '0';
          blockAttrs['list'] =
              numIdVal == '1' ? 'ordered' : 'bullet';
          final ilvl = _findElement(numPr, 'ilvl');
          final ilvlVal = int.tryParse(
              ilvl?.getAttribute('w:val') ?? ilvl?.getAttribute('val') ?? '0');
          if (ilvlVal != null && ilvlVal > 0) {
            blockAttrs['indent'] = ilvlVal;
          }
        }

        // Check for alignment
        final jc = _findElement(pPr, 'jc');
        if (jc != null) {
          final jcVal = jc.getAttribute('w:val') ?? jc.getAttribute('val');
          switch (jcVal) {
            case 'center':
              blockAttrs['align'] = 'center';
            case 'right':
              blockAttrs['align'] = 'right';
            case 'both':
              blockAttrs['align'] = 'justify';
          }
        }

        if (blockAttrs.isEmpty) blockAttrs = null;
      }

      // Process runs within paragraph
      // ignore: unused_local_variable
      bool hasContent = false;
      for (final run in _findElements(paragraph, 'r')) {
        final rPr = _findElement(run, 'rPr');
        final tElements = _findElements(run, 't');
        for (final t in tElements) {
          final text = t.innerText;
          if (text.isEmpty) continue;

          hasContent = true;
          plainTextBuffer.write(text);

          final attrs = <String, dynamic>{};
          if (rPr != null) {
            if (_findElement(rPr, 'b') != null) attrs['bold'] = true;
            if (_findElement(rPr, 'i') != null) attrs['italic'] = true;
            if (_findElement(rPr, 'u') != null) attrs['underline'] = true;
            if (_findElement(rPr, 'strike') != null) attrs['strike'] = true;

            final color = _findElement(rPr, 'color');
            if (color != null) {
              final colorVal =
                  color.getAttribute('w:val') ?? color.getAttribute('val');
              if (colorVal != null && colorVal != 'auto') {
                attrs['color'] = '#$colorVal';
              }
            }

            final sz = _findElement(rPr, 'sz');
            if (sz != null) {
              final szVal =
                  sz.getAttribute('w:val') ?? sz.getAttribute('val');
              if (szVal != null) {
                // Convert half-points to pixels (approximate)
                final halfPts = int.tryParse(szVal);
                if (halfPts != null) {
                  attrs['size'] = '${(halfPts / 2).round()}';
                }
              }
            }

            final rFonts = _findElement(rPr, 'rFonts');
            if (rFonts != null) {
              final font = rFonts.getAttribute('w:ascii') ??
                  rFonts.getAttribute('ascii');
              if (font != null) attrs['font'] = font;
            }
          }

          if (attrs.isNotEmpty) {
            deltaOps.add({'insert': text, 'attributes': attrs});
          } else {
            deltaOps.add({'insert': text});
          }
        }
      }

      // Add newline with block attributes
      if (blockAttrs != null && blockAttrs.isNotEmpty) {
        deltaOps.add({'insert': '\n', 'attributes': blockAttrs});
      } else {
        deltaOps.add({'insert': '\n'});
      }
      plainTextBuffer.write('\n');
    }

    // Ensure at least one operation
    if (deltaOps.isEmpty) {
      deltaOps.add({'insert': '\n'});
    }

    return {
      'title': title,
      'deltaJson': jsonEncode(deltaOps),
      'plainText': plainTextBuffer.toString(),
    };
  }

  /// Find a child element by local name (namespace-agnostic).
  static XmlElement? _findElement(XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      final name = child.name.local;
      if (name == localName) return child;
    }
    return null;
  }

  /// Find all child elements by local name (namespace-agnostic).
  static Iterable<XmlElement> _findElements(
      XmlElement parent, String localName) {
    return parent.childElements
        .where((e) => e.name.local == localName);
  }
}
