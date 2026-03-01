// Captures how the preview image is fitted inside the visible editor viewport.
/*
Dependency Memo
- Depends on: dart:ui Size and Offset geometry primitives.
- Requires methods: none.
- Provides methods: CanvasTransform.copyWith().
*/
import 'dart:ui';

class CanvasTransform {
  const CanvasTransform({
    required this.viewportSize,
    required this.imageRectOffset,
    required this.imageRenderSize,
  });

  final Size viewportSize;
  final Offset imageRectOffset;
  final Size imageRenderSize;

  static const CanvasTransform identity = CanvasTransform(
    viewportSize: Size.zero,
    imageRectOffset: Offset.zero,
    imageRenderSize: Size.zero,
  );

  CanvasTransform copyWith({
    Size? viewportSize,
    Offset? imageRectOffset,
    Size? imageRenderSize,
  }) {
    return CanvasTransform(
      viewportSize: viewportSize ?? this.viewportSize,
      imageRectOffset: imageRectOffset ?? this.imageRectOffset,
      imageRenderSize: imageRenderSize ?? this.imageRenderSize,
    );
  }

  bool closeTo(CanvasTransform other, {double tolerance = 0.25}) {
    return (viewportSize.width - other.viewportSize.width).abs() <= tolerance &&
        (viewportSize.height - other.viewportSize.height).abs() <= tolerance &&
        (imageRectOffset.dx - other.imageRectOffset.dx).abs() <= tolerance &&
        (imageRectOffset.dy - other.imageRectOffset.dy).abs() <= tolerance &&
        (imageRenderSize.width - other.imageRenderSize.width).abs() <=
            tolerance &&
        (imageRenderSize.height - other.imageRenderSize.height).abs() <=
            tolerance;
  }
}
