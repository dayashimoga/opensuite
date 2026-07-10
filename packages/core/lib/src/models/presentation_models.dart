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
  });

  SlideElement copyWith({
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
  }) {
    return SlideElement(
      id: id,
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
      );

  @override
  List<Object?> get props =>
      [id, type, x, y, width, height, content, zIndex];
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
