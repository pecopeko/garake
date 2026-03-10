// Stores normalized face bounds and landmarks so beauty edits can rerender without re-detecting.
/*
Dependency Memo
- Depends on: dart:ui geometry primitives for normalized coordinates.
- Requires methods: none.
- Provides methods: DetectedFace.resolveBounds(), resolvePoint(), hasUsableArea.
*/
import 'dart:ui';

class DetectedFace {
  const DetectedFace({
    required this.normalizedBounds,
    this.leftEye,
    this.rightEye,
    this.noseBase,
    this.bottomMouth,
    this.leftCheek,
    this.rightCheek,
    this.smileProbability,
  });

  final Rect normalizedBounds;
  final Offset? leftEye;
  final Offset? rightEye;
  final Offset? noseBase;
  final Offset? bottomMouth;
  final Offset? leftCheek;
  final Offset? rightCheek;
  final double? smileProbability;

  bool get hasUsableArea =>
      normalizedBounds.width > 0.05 && normalizedBounds.height > 0.05;

  Rect resolveBounds(Size imageSize) {
    return Rect.fromLTWH(
      normalizedBounds.left * imageSize.width,
      normalizedBounds.top * imageSize.height,
      normalizedBounds.width * imageSize.width,
      normalizedBounds.height * imageSize.height,
    );
  }

  Offset? resolvePoint(Offset? normalizedPoint, Size imageSize) {
    if (normalizedPoint == null) {
      return null;
    }
    return Offset(
      normalizedPoint.dx * imageSize.width,
      normalizedPoint.dy * imageSize.height,
    );
  }
}
