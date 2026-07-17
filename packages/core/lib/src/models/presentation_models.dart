import 'package:equatable/equatable.dart';

/// Represents a single element on a presentation slide.
class SlideElement extends Equatable {
  /// Unique element identifier.
  final String id;

  /// Element type: 'text', 'shape', 'image', 'table'.
  final String type;

  /// X position (percentage of slide width, 0.0-1.0).
  final double x;

  /// Y position (percentage of slide height, 0.0-1.0).
  final double y;

  /// Width (percentage of slide width).
  final double width;

  /// Height (percentage of slide height).
  final double height;

  /// Rotation in degrees.
  final double rotation;

  /// Text content (for text and table elements).
  final String content;

  /// Font size in points.
  final double fontSize;

  /// Font weight: 'normal', 'bold'.
  final String fontWeight;

  /// Text alignment: 'left', 'center', 'right'.
  final String textAlign;

  /// Text color as hex string.
  final String textColor;

  /// Background/fill color as hex string.
  final String? fillColor;

  /// Border color as hex string.
  final String? borderColor;

  /// Border width in pixels.
  final double borderWidth;

  /// Shape type for shape elements: 'rectangle', 'circle', 'triangle', 'arrow'.
  final String? shapeType;

  /// Image path/URL for image elements.
  final String? imagePath;

  /// Z-index for layer ordering.
  final int zIndex;

  /// Group identifier for grouped elements.
  final String? groupId;

  /// Opacity (0.0 to 1.0).
  final double opacity;

  const SlideElement({
    required this.id,
    required this.type,
    this.x = 0.1,
    this.y = 0.1,
    this.width = 0.3,
    this.height = 0.2,
    this.rotation = 0,
    this.content = '',
    this.fontSize = 24,
    this.fontWeight = 'normal',
    this.textAlign = 'center',
    this.textColor = '#000000',
    this.fillColor,
    this.borderColor,
    this.borderWidth = 0,
    this.shapeType,
    this.imagePath,
    this.zIndex = 0,
    this.groupId,
    this.opacity = 1.0,
  });

  SlideElement copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? content,
    double? fontSize,
    String? fontWeight,
    String? textAlign,
    String? textColor,
    String? fillColor,
    String? borderColor,
    double? borderWidth,
    String? shapeType,
    String? imagePath,
    int? zIndex,
    String? groupId,
    double? opacity,
  }) {
    return SlideElement(
      id: id ?? this.id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      content: content ?? this.content,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textAlign: textAlign ?? this.textAlign,
      textColor: textColor ?? this.textColor,
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      shapeType: shapeType ?? this.shapeType,
      imagePath: imagePath ?? this.imagePath,
      zIndex: zIndex ?? this.zIndex,
      groupId: groupId ?? this.groupId,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'content': content,
        'fontSize': fontSize,
        'fontWeight': fontWeight,
        'textAlign': textAlign,
        'textColor': textColor,
        if (fillColor != null) 'fillColor': fillColor,
        if (borderColor != null) 'borderColor': borderColor,
        'borderWidth': borderWidth,
        if (shapeType != null) 'shapeType': shapeType,
        if (imagePath != null) 'imagePath': imagePath,
        'zIndex': zIndex,
        if (groupId != null) 'groupId': groupId,
        'opacity': opacity,
      };

  factory SlideElement.fromMap(Map<String, dynamic> map) => SlideElement(
        id: map['id'] as String,
        type: map['type'] as String,
        x: (map['x'] as num?)?.toDouble() ?? 0.1,
        y: (map['y'] as num?)?.toDouble() ?? 0.1,
        width: (map['width'] as num?)?.toDouble() ?? 0.3,
        height: (map['height'] as num?)?.toDouble() ?? 0.2,
        rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
        content: (map['content'] as String?) ?? '',
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 24,
        fontWeight: (map['fontWeight'] as String?) ?? 'normal',
        textAlign: (map['textAlign'] as String?) ?? 'center',
        textColor: (map['textColor'] as String?) ?? '#000000',
        fillColor: map['fillColor'] as String?,
        borderColor: map['borderColor'] as String?,
        borderWidth: (map['borderWidth'] as num?)?.toDouble() ?? 0,
        shapeType: map['shapeType'] as String?,
        imagePath: map['imagePath'] as String?,
        zIndex: (map['zIndex'] as int?) ?? 0,
        groupId: map['groupId'] as String?,
        opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props =>
      [id, type, x, y, width, height, content, zIndex, groupId, opacity];
}

/// Represents a single slide in a presentation.
class SlideData extends Equatable {
  /// Unique slide identifier.
  final String id;

  /// Slide background color.
  final String backgroundColor;

  /// Background image path (optional).
  final String? backgroundImage;

  /// Elements on this slide.
  final List<SlideElement> elements;

  /// Speaker notes for this slide.
  final String speakerNotes;

  /// Slide transition type: 'none', 'fade', 'slide', 'zoom'.
  final String transition;

  /// Slide layout name.
  final String layout;

  const SlideData({
    required this.id,
    this.backgroundColor = '#FFFFFF',
    this.backgroundImage,
    this.elements = const [],
    this.speakerNotes = '',
    this.transition = 'none',
    this.layout = 'blank',
  });

  SlideData copyWith({
    String? backgroundColor,
    String? backgroundImage,
    List<SlideElement>? elements,
    String? speakerNotes,
    String? transition,
    String? layout,
  }) {
    return SlideData(
      id: id,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      elements: elements ?? this.elements,
      speakerNotes: speakerNotes ?? this.speakerNotes,
      transition: transition ?? this.transition,
      layout: layout ?? this.layout,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'backgroundColor': backgroundColor,
        if (backgroundImage != null) 'backgroundImage': backgroundImage,
        'elements': elements.map((e) => e.toMap()).toList(),
        'speakerNotes': speakerNotes,
        'transition': transition,
        'layout': layout,
      };

  factory SlideData.fromMap(Map<String, dynamic> map) => SlideData(
        id: map['id'] as String,
        backgroundColor: (map['backgroundColor'] as String?) ?? '#FFFFFF',
        backgroundImage: map['backgroundImage'] as String?,
        elements: (map['elements'] as List?)
                ?.map((e) => SlideElement.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        speakerNotes: (map['speakerNotes'] as String?) ?? '',
        transition: (map['transition'] as String?) ?? 'none',
        layout: (map['layout'] as String?) ?? 'blank',
      );

  @override
  List<Object?> get props =>
      [id, backgroundColor, elements, speakerNotes, transition];
}

/// Represents a table element within a slide.
class SlideTable extends Equatable {
  final String id;
  final int rows;
  final int columns;
  final Map<String, String> cells; // 'row,col' -> content
  final Map<String, String> cellStyles; // 'row,col' -> JSON style
  final double cellPadding;
  final String borderColor;
  final double borderWidth;
  final String? headerColor;

  const SlideTable({
    required this.id,
    this.rows = 3,
    this.columns = 3,
    this.cells = const {},
    this.cellStyles = const {},
    this.cellPadding = 8.0,
    this.borderColor = '#333333',
    this.borderWidth = 1.0,
    this.headerColor,
  });

  String getCell(int row, int col) => cells['$row,$col'] ?? '';

  SlideTable copyWith({
    int? rows,
    int? columns,
    Map<String, String>? cells,
    Map<String, String>? cellStyles,
    double? cellPadding,
    String? borderColor,
    double? borderWidth,
    String? headerColor,
  }) {
    return SlideTable(
      id: id,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      cells: cells ?? this.cells,
      cellStyles: cellStyles ?? this.cellStyles,
      cellPadding: cellPadding ?? this.cellPadding,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      headerColor: headerColor ?? this.headerColor,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'rows': rows,
        'columns': columns,
        'cells': cells,
        'cellStyles': cellStyles,
        'cellPadding': cellPadding,
        'borderColor': borderColor,
        'borderWidth': borderWidth,
        if (headerColor != null) 'headerColor': headerColor,
      };

  factory SlideTable.fromMap(Map<String, dynamic> map) => SlideTable(
        id: map['id'] as String,
        rows: (map['rows'] as int?) ?? 3,
        columns: (map['columns'] as int?) ?? 3,
        cells: Map<String, String>.from(map['cells'] as Map? ?? {}),
        cellStyles: Map<String, String>.from(map['cellStyles'] as Map? ?? {}),
        cellPadding: (map['cellPadding'] as num?)?.toDouble() ?? 8.0,
        borderColor: (map['borderColor'] as String?) ?? '#333333',
        borderWidth: (map['borderWidth'] as num?)?.toDouble() ?? 1.0,
        headerColor: map['headerColor'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, rows, columns, cells, borderColor, headerColor];
}

/// Represents an animation applied to a slide element.
class SlideAnimation extends Equatable {
  final String id;
  final String targetElementId;

  /// Animation type: 'fadeIn', 'fadeOut', 'slideLeft', 'slideRight',
  /// 'slideUp', 'slideDown', 'zoomIn', 'zoomOut', 'bounce', 'spin'.
  final String type;

  /// Duration in milliseconds.
  final int durationMs;

  /// Delay before animation starts in milliseconds.
  final int delayMs;

  /// Trigger: 'onClick', 'afterPrevious', 'withPrevious'.
  final String trigger;

  /// Order in the animation sequence.
  final int order;

  const SlideAnimation({
    required this.id,
    required this.targetElementId,
    this.type = 'fadeIn',
    this.durationMs = 500,
    this.delayMs = 0,
    this.trigger = 'onClick',
    this.order = 0,
  });

  SlideAnimation copyWith({
    String? targetElementId,
    String? type,
    int? durationMs,
    int? delayMs,
    String? trigger,
    int? order,
  }) {
    return SlideAnimation(
      id: id,
      targetElementId: targetElementId ?? this.targetElementId,
      type: type ?? this.type,
      durationMs: durationMs ?? this.durationMs,
      delayMs: delayMs ?? this.delayMs,
      trigger: trigger ?? this.trigger,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'targetElementId': targetElementId,
        'type': type,
        'durationMs': durationMs,
        'delayMs': delayMs,
        'trigger': trigger,
        'order': order,
      };

  factory SlideAnimation.fromMap(Map<String, dynamic> map) => SlideAnimation(
        id: map['id'] as String,
        targetElementId: map['targetElementId'] as String,
        type: (map['type'] as String?) ?? 'fadeIn',
        durationMs: (map['durationMs'] as int?) ?? 500,
        delayMs: (map['delayMs'] as int?) ?? 0,
        trigger: (map['trigger'] as String?) ?? 'onClick',
        order: (map['order'] as int?) ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, targetElementId, type, durationMs, delayMs, trigger, order];
}

/// Represents a slide master/layout template.
class SlideMaster extends Equatable {
  final String id;
  final String name;

  /// Layout type: 'title', 'titleContent', 'twoColumn', 'blank',
  /// 'sectionHeader', 'comparison', 'titleOnly', 'captionedContent'.
  final String layoutType;
  final String backgroundColor;
  final String? backgroundImage;

  /// Placeholder positions as SlideElements.
  final List<SlideElement> placeholders;

  const SlideMaster({
    required this.id,
    required this.name,
    this.layoutType = 'blank',
    this.backgroundColor = '#FFFFFF',
    this.backgroundImage,
    this.placeholders = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'layoutType': layoutType,
        'backgroundColor': backgroundColor,
        if (backgroundImage != null) 'backgroundImage': backgroundImage,
        'placeholders': placeholders.map((e) => e.toMap()).toList(),
      };

  factory SlideMaster.fromMap(Map<String, dynamic> map) => SlideMaster(
        id: map['id'] as String,
        name: map['name'] as String,
        layoutType: (map['layoutType'] as String?) ?? 'blank',
        backgroundColor: (map['backgroundColor'] as String?) ?? '#FFFFFF',
        backgroundImage: map['backgroundImage'] as String?,
        placeholders: (map['placeholders'] as List?)
                ?.map((e) => SlideElement.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [id, name, layoutType, backgroundColor];
}
