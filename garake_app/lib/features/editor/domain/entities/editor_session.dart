// Aggregates image bytes, face-retouch context, fitting metadata, and mutable sticker editing state.
/*
Dependency Memo
- Depends on: sticker_item.dart, filter_config.dart, face_retouch_level.dart, detected_face.dart, and canvas_transform.dart entities.
- Requires methods: StickerItem.copyWith(), CanvasTransform.copyWith().
- Provides methods: EditorSession.copyWith().
*/
import 'dart:typed_data';
import 'dart:ui';

import 'canvas_transform.dart';
import 'detected_face.dart';
import 'face_retouch_level.dart';
import 'filter_config.dart';
import 'sticker_item.dart';

class EditorSession {
  const EditorSession({
    required this.originalBytes,
    required this.filteredBytes,
    required this.originalImageSize,
    required this.stickers,
    required this.stampDate,
    required this.detectedFaces,
    required this.faceRetouchLevel,
    required this.filterConfig,
    required this.canvasTransform,
  });

  final Uint8List originalBytes;
  final Uint8List filteredBytes;
  final Size originalImageSize;
  final List<StickerItem> stickers;
  final DateTime stampDate;
  final List<DetectedFace> detectedFaces;
  final FaceRetouchLevel faceRetouchLevel;
  final FilterConfig filterConfig;
  final CanvasTransform canvasTransform;

  bool get canRetouchFace => detectedFaces.isNotEmpty;

  StickerItem? get selectedSticker {
    for (final StickerItem sticker in stickers) {
      if (sticker.selected) {
        return sticker;
      }
    }
    return null;
  }

  EditorSession copyWith({
    Uint8List? originalBytes,
    Uint8List? filteredBytes,
    Size? originalImageSize,
    List<StickerItem>? stickers,
    DateTime? stampDate,
    List<DetectedFace>? detectedFaces,
    FaceRetouchLevel? faceRetouchLevel,
    FilterConfig? filterConfig,
    CanvasTransform? canvasTransform,
  }) {
    return EditorSession(
      originalBytes: originalBytes ?? this.originalBytes,
      filteredBytes: filteredBytes ?? this.filteredBytes,
      originalImageSize: originalImageSize ?? this.originalImageSize,
      stickers: stickers ?? this.stickers,
      stampDate: stampDate ?? this.stampDate,
      detectedFaces: detectedFaces ?? this.detectedFaces,
      faceRetouchLevel: faceRetouchLevel ?? this.faceRetouchLevel,
      filterConfig: filterConfig ?? this.filterConfig,
      canvasTransform: canvasTransform ?? this.canvasTransform,
    );
  }
}
