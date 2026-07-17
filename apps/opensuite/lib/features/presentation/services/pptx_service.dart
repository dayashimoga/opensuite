import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:fileutility_core/fileutility_core.dart';
import 'package:xml/xml.dart';

/// Service for importing and exporting PPTX (PowerPoint) files.
///
/// Uses ZIP + OOXML approach. Exports slides as XML within a valid
/// PPTX archive structure.
class PptxService {
  PptxService._();

  // --- OOXML Constants ---
  static const _nsA = 'http://schemas.openxmlformats.org/drawingml/2006/main';
  static const _nsR =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const _nsP =
      'http://schemas.openxmlformats.org/presentationml/2006/main';
  static const _nsCT =
      'http://schemas.openxmlformats.org/package/2006/content-types';
  static const _nsRels =
      'http://schemas.openxmlformats.org/package/2006/relationships';

  /// Export presentation slides to PPTX bytes.
  static Uint8List exportToPptx({
    required List<SlideData> slides,
    required String title,
    int slideWidth = 9144000, // EMU: 10 inches
    int slideHeight = 6858000, // EMU: 7.5 inches
  }) {
    final archive = Archive();

    // Build slide XMLs
    final slideXmls = <String>[];
    for (int i = 0; i < slides.length; i++) {
      slideXmls.add(_buildSlideXml(slides[i], slideWidth, slideHeight));
    }

    // [Content_Types].xml
    archive.addFile(ArchiveFile(
      '[Content_Types].xml',
      0,
      utf8.encode(_buildContentTypes(slides.length)),
    ));

    // _rels/.rels
    archive.addFile(ArchiveFile(
      '_rels/.rels',
      0,
      utf8.encode(_buildRootRels()),
    ));

    // ppt/presentation.xml
    archive.addFile(ArchiveFile(
      'ppt/presentation.xml',
      0,
      utf8.encode(
          _buildPresentationXml(slides.length, slideWidth, slideHeight)),
    ));

    // ppt/_rels/presentation.xml.rels
    archive.addFile(ArchiveFile(
      'ppt/_rels/presentation.xml.rels',
      0,
      utf8.encode(_buildPresentationRels(slides.length)),
    ));

    // ppt/slideMasters/slideMaster1.xml
    archive.addFile(ArchiveFile(
      'ppt/slideMasters/slideMaster1.xml',
      0,
      utf8.encode(_buildSlideMasterXml()),
    ));

    // ppt/slideMasters/_rels/slideMaster1.xml.rels
    archive.addFile(ArchiveFile(
      'ppt/slideMasters/_rels/slideMaster1.xml.rels',
      0,
      utf8.encode(_buildSlideMasterRels()),
    ));

    // ppt/slideLayouts/slideLayout1.xml
    archive.addFile(ArchiveFile(
      'ppt/slideLayouts/slideLayout1.xml',
      0,
      utf8.encode(_buildSlideLayoutXml()),
    ));

    // ppt/slideLayouts/_rels/slideLayout1.xml.rels
    archive.addFile(ArchiveFile(
      'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
      0,
      utf8.encode(_buildSlideLayoutRels()),
    ));

    // ppt/theme/theme1.xml
    archive.addFile(ArchiveFile(
      'ppt/theme/theme1.xml',
      0,
      utf8.encode(_buildThemeXml()),
    ));

    // Slide files
    for (int i = 0; i < slideXmls.length; i++) {
      archive.addFile(ArchiveFile(
        'ppt/slides/slide${i + 1}.xml',
        0,
        utf8.encode(slideXmls[i]),
      ));

      // Slide rels
      archive.addFile(ArchiveFile(
        'ppt/slides/_rels/slide${i + 1}.xml.rels',
        0,
        utf8.encode(_buildSlideRels()),
      ));
    }

    // docProps/core.xml
    archive.addFile(ArchiveFile(
      'docProps/core.xml',
      0,
      utf8.encode(_buildCoreXml(title)),
    ));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData!);
  }

  /// Import PPTX bytes to a list of SlideData.
  static List<SlideData> importFromPptx({required Uint8List fileBytes}) {
    final archive = ZipDecoder().decodeBytes(fileBytes);
    final slides = <SlideData>[];

    // Find slide files
    final slideFiles = archive.files
        .where((f) =>
            f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final slideFile in slideFiles) {
      final content = utf8.decode(slideFile.content as List<int>);
      try {
        final doc = XmlDocument.parse(content);
        slides.add(_parseSlideXml(doc));
      } catch (_) {
        // Skip unparseable slides
        slides.add(SlideData(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
        ));
      }
    }

    if (slides.isEmpty) {
      slides.add(SlideData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
      ));
    }

    return slides;
  }

  // --- Export Helpers ---

  static String _buildSlideXml(
      SlideData slide, int slideWidth, int slideHeight) {
    final elements = StringBuffer();

    for (final element in slide.elements) {
      switch (element.type) {
        case 'text':
          elements.write(_buildTextShapeXml(element, slideWidth, slideHeight));
        case 'shape':
          elements.write(_buildShapeXml(element, slideWidth, slideHeight));
        case 'image':
          // Images require relationships — simplified as placeholder
          elements.write(_buildTextShapeXml(
            element.copyWith(content: '[Image: ${element.imagePath}]'),
            slideWidth,
            slideHeight,
          ));
        default:
          elements.write(_buildTextShapeXml(element, slideWidth, slideHeight));
      }
    }

    final bgColor = slide.backgroundColor.replaceFirst('#', '');

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="$_nsA" xmlns:r="$_nsR" xmlns:p="$_nsP">
  <p:cSld>
    <p:bg><p:bgPr><a:solidFill><a:srgbClr val="$bgColor"/></a:solidFill><a:effectLst/></p:bgPr></p:bg>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
$elements
    </p:spTree>
  </p:cSld>
</p:sld>''';
  }

  static String _buildTextShapeXml(
      SlideElement el, int slideWidth, int slideHeight) {
    final x = (el.x * slideWidth).round();
    final y = (el.y * slideHeight).round();
    final cx = (el.width * slideWidth).round();
    final cy = (el.height * slideHeight).round();
    final rot = (el.rotation * 60000).round(); // degrees to 60000ths
    final fontSize = (el.fontSize * 100).round(); // pt to hundredths
    final textColor = el.textColor.replaceFirst('#', '');
    final bold = el.fontWeight == 'bold' ? ' b="1"' : '';
    final align = switch (el.textAlign) {
      'center' => 'ctr',
      'right' => 'r',
      _ => 'l',
    };
    final escaped = _xmlEscape(el.content);

    final fillXml = el.fillColor != null
        ? '<a:solidFill><a:srgbClr val="${el.fillColor!.replaceFirst('#', '')}"/></a:solidFill>'
        : '<a:noFill/>';

    return '''
      <p:sp>
        <p:nvSpPr><p:cNvPr id="${el.id.hashCode.abs() % 10000 + 2}" name="${_xmlEscape(el.id)}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm rot="$rot"><a:off x="$x" y="$y"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>
          <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
          $fillXml
        </p:spPr>
        <p:txBody>
          <a:bodyPr/>
          <a:lstStyle/>
          <a:p><a:pPr algn="$align"/><a:r><a:rPr lang="en-US" sz="$fontSize"$bold><a:solidFill><a:srgbClr val="$textColor"/></a:solidFill></a:rPr><a:t>$escaped</a:t></a:r></a:p>
        </p:txBody>
      </p:sp>''';
  }

  static String _buildShapeXml(
      SlideElement el, int slideWidth, int slideHeight) {
    final x = (el.x * slideWidth).round();
    final y = (el.y * slideHeight).round();
    final cx = (el.width * slideWidth).round();
    final cy = (el.height * slideHeight).round();
    final rot = (el.rotation * 60000).round();

    final preset = switch (el.shapeType) {
      'circle' => 'ellipse',
      'triangle' => 'triangle',
      'arrow' => 'rightArrow',
      _ => 'rect',
    };

    final fillXml = el.fillColor != null
        ? '<a:solidFill><a:srgbClr val="${el.fillColor!.replaceFirst('#', '')}"/></a:solidFill>'
        : '<a:noFill/>';

    return '''
      <p:sp>
        <p:nvSpPr><p:cNvPr id="${el.id.hashCode.abs() % 10000 + 2}" name="${_xmlEscape(el.id)}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm rot="$rot"><a:off x="$x" y="$y"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>
          <a:prstGeom prst="$preset"><a:avLst/></a:prstGeom>
          $fillXml
        </p:spPr>
      </p:sp>''';
  }

  // --- Import Helpers ---

  static SlideData _parseSlideXml(XmlDocument doc) {
    final elements = <SlideElement>[];
    String bgColor = '#FFFFFF';

    // Parse background
    final bgNodes = doc.findAllElements('srgbClr', namespace: _nsA);
    for (final bg in bgNodes) {
      // Take the first one as background if it's under bg element
      final parent = bg.parent?.parent?.parent;
      if (parent is XmlElement && parent.name.local == 'bg') {
        bgColor = '#${bg.getAttribute('val') ?? 'FFFFFF'}';
        break;
      }
    }

    // Parse shapes
    final shapes = doc.findAllElements('sp', namespace: _nsP);
    int idx = 0;
    for (final sp in shapes) {
      try {
        elements.add(_parseShapeElement(sp, idx++));
      } catch (_) {
        // Skip unparseable elements
      }
    }

    return SlideData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      backgroundColor: bgColor,
      elements: elements,
    );
  }

  static SlideElement _parseShapeElement(XmlElement sp, int index) {
    // Extract position
    double x = 0.1, y = 0.1, w = 0.3, h = 0.2;
    double rotation = 0;
    final xfrm = sp.findAllElements('xfrm', namespace: _nsA).firstOrNull;
    if (xfrm != null) {
      final off = xfrm.findElements('off', namespace: _nsA).firstOrNull;
      final ext = xfrm.findElements('ext', namespace: _nsA).firstOrNull;
      if (off != null) {
        x = (int.tryParse(off.getAttribute('x') ?? '0') ?? 0) / 9144000;
        y = (int.tryParse(off.getAttribute('y') ?? '0') ?? 0) / 6858000;
      }
      if (ext != null) {
        w = (int.tryParse(ext.getAttribute('cx') ?? '0') ?? 0) / 9144000;
        h = (int.tryParse(ext.getAttribute('cy') ?? '0') ?? 0) / 6858000;
      }
      rotation = (int.tryParse(xfrm.getAttribute('rot') ?? '0') ?? 0) / 60000;
    }

    // Extract text
    String content = '';
    double fontSize = 24;
    String fontWeight = 'normal';
    String textAlign = 'center';
    String textColor = '#000000';

    final txBody = sp.findAllElements('txBody', namespace: _nsP).firstOrNull;
    if (txBody != null) {
      final runs = txBody.findAllElements('t', namespace: _nsA);
      content = runs.map((r) => r.innerText).join();

      final rPr = txBody.findAllElements('rPr', namespace: _nsA).firstOrNull;
      if (rPr != null) {
        final sz = rPr.getAttribute('sz');
        if (sz != null) fontSize = (int.tryParse(sz) ?? 2400) / 100;
        if (rPr.getAttribute('b') == '1') fontWeight = 'bold';

        final fill = rPr.findElements('solidFill', namespace: _nsA).firstOrNull;
        if (fill != null) {
          final clr = fill.findElements('srgbClr', namespace: _nsA).firstOrNull;
          if (clr != null) {
            textColor = '#${clr.getAttribute('val') ?? '000000'}';
          }
        }
      }

      final pPr = txBody.findAllElements('pPr', namespace: _nsA).firstOrNull;
      if (pPr != null) {
        final algn = pPr.getAttribute('algn');
        textAlign = switch (algn) {
          'ctr' => 'center',
          'r' => 'right',
          _ => 'left',
        };
      }
    }

    // Extract fill color
    String? fillColor;
    final spPr = sp.findAllElements('spPr', namespace: _nsP).firstOrNull;
    if (spPr != null) {
      final solidFill =
          spPr.findElements('solidFill', namespace: _nsA).firstOrNull;
      if (solidFill != null) {
        final clr =
            solidFill.findElements('srgbClr', namespace: _nsA).firstOrNull;
        if (clr != null) fillColor = '#${clr.getAttribute('val') ?? 'FFFFFF'}';
      }
    }

    // Determine type
    String type = content.isNotEmpty ? 'text' : 'shape';
    String? shapeType;
    final geom = sp.findAllElements('prstGeom', namespace: _nsA).firstOrNull;
    if (geom != null) {
      final prst = geom.getAttribute('prst');
      if (prst != null && prst != 'rect') {
        type = 'shape';
        shapeType = switch (prst) {
          'ellipse' => 'circle',
          'triangle' => 'triangle',
          'rightArrow' || 'leftArrow' => 'arrow',
          _ => 'rectangle',
        };
      }
    }

    return SlideElement(
      id: 'el_${index}_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      width: w.clamp(0.01, 1.0),
      height: h.clamp(0.01, 1.0),
      rotation: rotation,
      content: content,
      fontSize: fontSize,
      fontWeight: fontWeight,
      textAlign: textAlign,
      textColor: textColor,
      fillColor: fillColor,
      shapeType: shapeType,
    );
  }

  // --- OOXML Structure Generators ---

  static String _buildContentTypes(int slideCount) {
    final slideTypes = StringBuffer();
    for (int i = 1; i <= slideCount; i++) {
      slideTypes.write(
          '<Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>');
    }
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="$_nsCT">
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  $slideTypes
</Types>''';
  }

  static String _buildRootRels() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="$_nsRels">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
</Relationships>''';

  static String _buildPresentationXml(
      int slideCount, int slideWidth, int slideHeight) {
    final slideRefs = StringBuffer();
    for (int i = 1; i <= slideCount; i++) {
      slideRefs.write('<p:sldId id="${255 + i}" r:id="rId${i + 2}"/>');
    }
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="$_nsA" xmlns:r="$_nsR" xmlns:p="$_nsP">
  <p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>
  <p:sldIdLst>$slideRefs</p:sldIdLst>
  <p:sldSz cx="$slideWidth" cy="$slideHeight"/>
  <p:notesSz cx="$slideHeight" cy="$slideWidth"/>
</p:presentation>''';
  }

  static String _buildPresentationRels(int slideCount) {
    final rels = StringBuffer();
    rels.write(
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>');
    rels.write(
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>');
    for (int i = 1; i <= slideCount; i++) {
      rels.write(
          '<Relationship Id="rId${i + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>');
    }
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="$_nsRels">$rels</Relationships>''';
  }

  static String _buildSlideRels() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="$_nsRels">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';

  static String _buildSlideMasterXml() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="$_nsA" xmlns:r="$_nsR" xmlns:p="$_nsP">
  <p:cSld><p:bg><p:bgPr><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill><a:effectLst/></p:bgPr></p:bg><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
  <p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>
</p:sldMaster>''';

  static String _buildSlideMasterRels() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="$_nsRels">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';

  static String _buildSlideLayoutXml() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="$_nsA" xmlns:r="$_nsR" xmlns:p="$_nsP" type="blank" preserve="1">
  <p:cSld name="Blank"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sldLayout>''';

  static String _buildSlideLayoutRels() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="$_nsRels">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>''';

  static String _buildThemeXml() =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="$_nsA" name="Office Theme">
  <a:themeElements>
    <a:clrScheme name="Office">
      <a:dk1><a:srgbClr val="000000"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="44546A"/></a:dk2>
      <a:lt2><a:srgbClr val="E7E6E6"/></a:lt2>
      <a:accent1><a:srgbClr val="4472C4"/></a:accent1>
      <a:accent2><a:srgbClr val="ED7D31"/></a:accent2>
      <a:accent3><a:srgbClr val="A5A5A5"/></a:accent3>
      <a:accent4><a:srgbClr val="FFC000"/></a:accent4>
      <a:accent5><a:srgbClr val="5B9BD5"/></a:accent5>
      <a:accent6><a:srgbClr val="70AD47"/></a:accent6>
      <a:hlink><a:srgbClr val="0563C1"/></a:hlink>
      <a:folHlink><a:srgbClr val="954F72"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Office"><a:majorFont><a:latin typeface="Calibri Light"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont><a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont></a:fontScheme>
    <a:fmtScheme name="Office"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="6350"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="12700"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="19050"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst></a:fmtScheme>
  </a:themeElements>
</a:theme>''';

  static String _buildCoreXml(String title) {
    final now = DateTime.now().toUtc().toIso8601String();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>${_xmlEscape(title)}</dc:title>
  <dc:creator>OpenSuite</dc:creator>
  <dcterms:created xsi:type="dcterms:W3CDTF">$now</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$now</dcterms:modified>
</cp:coreProperties>''';
  }

  static String _xmlEscape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
