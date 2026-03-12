// Applies localized smoothing, lift, and contour accents so detected faces look more flattering.
/*
Dependency Memo
- Depends on: garake_filter_engine_impl.dart library imports and detected_face.dart / face_retouch_level.dart entities.
- Requires methods: image pixel access APIs and shared helper math functions from the main filter library.
- Provides methods: _applyFaceRetouch().
*/
part of 'garake_filter_engine_impl.dart';

void _applyFaceRetouch(
  img.Image image,
  List<DetectedFace> detectedFaces,
  FaceRetouchLevel level,
) {
  if (!level.isEnabled || detectedFaces.isEmpty) {
    return;
  }

  final _FaceRetouchProfile profile = _FaceRetouchProfile.fromLevel(level);
  _applyFaceShapeTuning(image, detectedFaces, profile);
  final img.Image source = img.Image.from(image);
  final img.Image blurred = img.Image.from(image);
  img.gaussianBlur(blurred, radius: profile.blurRadius);

  final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
  for (final DetectedFace face in detectedFaces) {
    final Rect bounds = face.resolveBounds(imageSize);
    if (bounds.width < 24 || bounds.height < 24) {
      continue;
    }
    _retouchFace(image, source, blurred, face, bounds, imageSize, profile);
  }
}

void _applyFaceShapeTuning(
  img.Image image,
  List<DetectedFace> detectedFaces,
  _FaceRetouchProfile profile,
) {
  final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
  for (final DetectedFace face in detectedFaces) {
    final Rect bounds = face.resolveBounds(imageSize);
    if (bounds.width < 24 || bounds.height < 24) {
      continue;
    }

    final Offset leftCheek =
        face.resolvePoint(face.leftCheek, imageSize) ??
        Offset(
          bounds.left + bounds.width * 0.22,
          bounds.top + bounds.height * 0.58,
        );
    final Offset rightCheek =
        face.resolvePoint(face.rightCheek, imageSize) ??
        Offset(
          bounds.right - bounds.width * 0.22,
          bounds.top + bounds.height * 0.58,
        );
    final Offset chinCenter = Offset(
      bounds.center.dx,
      bounds.bottom - bounds.height * 0.10,
    );

    _applyLocalBulge(
      image,
      center: leftCheek,
      radius: max(bounds.width * 0.18, 18),
      strength: -profile.cheekPinch,
    );
    _applyLocalBulge(
      image,
      center: rightCheek,
      radius: max(bounds.width * 0.18, 18),
      strength: -profile.cheekPinch,
    );
    _applyLocalBulge(
      image,
      center: chinCenter,
      radius: max(bounds.width * 0.22, 20),
      strength: -profile.chinPinch,
    );
  }
}

void _applyLocalBulge(
  img.Image image, {
  required Offset? center,
  required double radius,
  required double strength,
}) {
  if (center == null || radius <= 1 || strength.abs() < 0.001) {
    return;
  }

  img.bulgeDistortion(
    image,
    centerX: center.dx.round(),
    centerY: center.dy.round(),
    radius: radius,
    scale: strength,
    interpolation: img.Interpolation.linear,
  );
}

void _retouchFace(
  img.Image image,
  img.Image source,
  img.Image blurred,
  DetectedFace face,
  Rect bounds,
  Size imageSize,
  _FaceRetouchProfile profile,
) {
  final Rect expanded = bounds.inflate(bounds.width * 0.14);
  final int x0 = expanded.left.floor().clamp(0, image.width - 1);
  final int y0 = expanded.top.floor().clamp(0, image.height - 1);
  final int x1 = expanded.right.ceil().clamp(0, image.width - 1);
  final int y1 = expanded.bottom.ceil().clamp(0, image.height - 1);

  final Offset center =
      face.resolvePoint(face.noseBase, imageSize) ?? bounds.center;
  final double radiusX = max(bounds.width * 0.58, 18);
  final double radiusY = max(bounds.height * 0.72, 22);
  final Offset? leftEye = face.resolvePoint(face.leftEye, imageSize);
  final Offset? rightEye = face.resolvePoint(face.rightEye, imageSize);
  final Offset? mouth = face.resolvePoint(face.bottomMouth, imageSize);
  final Offset? leftCheek = face.resolvePoint(face.leftCheek, imageSize);
  final Offset? rightCheek = face.resolvePoint(face.rightCheek, imageSize);

  for (int y = y0; y <= y1; y++) {
    for (int x = x0; x <= x1; x++) {
      final double dx = (x - center.dx) / radiusX;
      final double dy = (y - center.dy) / radiusY;
      final double ellipse = dx * dx + dy * dy;
      if (ellipse >= 1.08) {
        continue;
      }

      final double faceMask = pow(
        (1.0 - ellipse).clamp(0.0, 1.0),
        1.45,
      ).toDouble();
      final double skinMask =
          (faceMask *
                  (1.0 -
                      max(
                        _featureMask(
                          x,
                          y,
                          leftEye,
                          bounds.width * 0.12,
                          bounds.height * 0.08,
                        ),
                        max(
                          _featureMask(
                            x,
                            y,
                            rightEye,
                            bounds.width * 0.12,
                            bounds.height * 0.08,
                          ),
                          _featureMask(
                            x,
                            y,
                            mouth,
                            bounds.width * 0.14,
                            bounds.height * 0.10,
                          ),
                        ),
                      )))
              .clamp(0.0, 1.0);

      final img.Pixel original = source.getPixel(x, y);
      final img.Pixel soft = blurred.getPixel(x, y);

      double r = _mix(
        original.r.toDouble(),
        soft.r.toDouble(),
        profile.skinSoftness * skinMask,
      );
      double g = _mix(
        original.g.toDouble(),
        soft.g.toDouble(),
        profile.skinSoftness * skinMask,
      );
      double b = _mix(
        original.b.toDouble(),
        soft.b.toDouble(),
        profile.skinSoftness * skinMask,
      );

      final double centerGlow =
          (1.0 - dx.abs()).clamp(0.0, 1.0) *
          (1.0 - (dy + 0.1).abs()).clamp(0.0, 1.0) *
          faceMask;
      final double edgeShade =
          _smoothStep(0.32, 0.92, dx.abs()) *
          (1.0 - (dy - 0.1).abs().clamp(0.0, 1.0)) *
          faceMask;
      final double lipTint = _featureMask(
        x,
        y,
        mouth,
        bounds.width * 0.16,
        bounds.height * 0.08,
      );
      final double blush = max(
        _featureMask(
          x,
          y,
          leftCheek,
          bounds.width * 0.15,
          bounds.height * 0.12,
        ),
        _featureMask(
          x,
          y,
          rightCheek,
          bounds.width * 0.15,
          bounds.height * 0.12,
        ),
      );

      final double lift =
          (profile.faceLift * faceMask) + (profile.centerGlow * centerGlow);
      final double contour = profile.edgeShade * edgeShade;
      final double skinBrighten = profile.skinBrighten * skinMask;

      r = (r + 255 * lift) * (1.0 - contour * 0.08);
      g = (g + 255 * lift * 0.92) * (1.0 - contour * 0.05);
      b = (b + 255 * lift * 0.88) * (1.0 - contour * 0.03);

      r += 255 * skinBrighten * 0.018;
      g += 255 * skinBrighten * 0.014;
      b += 255 * skinBrighten * 0.012;

      r += 255 * blush * profile.cheekTint * 0.10;
      g += 255 * blush * profile.cheekTint * 0.04;
      b += 255 * blush * profile.cheekTint * 0.06;

      r += 255 * lipTint * profile.lipTint * 0.08;
      g -= 255 * lipTint * profile.lipTint * 0.012;
      b += 255 * lipTint * profile.lipTint * 0.03;

      image.setPixelRgba(x, y, _clamp8(r), _clamp8(g), _clamp8(b), original.a);
    }
  }
}

double _featureMask(
  int x,
  int y,
  Offset? center,
  double radiusX,
  double radiusY,
) {
  if (center == null || radiusX <= 0 || radiusY <= 0) {
    return 0;
  }
  final double dx = (x - center.dx) / radiusX;
  final double dy = (y - center.dy) / radiusY;
  final double distance = dx * dx + dy * dy;
  if (distance >= 1) {
    return 0;
  }
  return pow(1.0 - distance, 1.5).toDouble();
}

double _mix(double a, double b, double t) {
  final double clamped = t.clamp(0.0, 1.0);
  return a * (1.0 - clamped) + b * clamped;
}

class _FaceRetouchProfile {
  const _FaceRetouchProfile({
    required this.blurRadius,
    required this.skinSoftness,
    required this.faceLift,
    required this.centerGlow,
    required this.edgeShade,
    required this.skinBrighten,
    required this.cheekPinch,
    required this.chinPinch,
    required this.cheekTint,
    required this.lipTint,
  });

  final int blurRadius;
  final double skinSoftness;
  final double faceLift;
  final double centerGlow;
  final double edgeShade;
  final double skinBrighten;
  final double cheekPinch;
  final double chinPinch;
  final double cheekTint;
  final double lipTint;

  factory _FaceRetouchProfile.fromLevel(FaceRetouchLevel level) {
    return switch (level) {
      FaceRetouchLevel.off => const _FaceRetouchProfile(
        blurRadius: 0,
        skinSoftness: 0,
        faceLift: 0,
        centerGlow: 0,
        edgeShade: 0,
        skinBrighten: 0,
        cheekPinch: 0,
        chinPinch: 0,
        cheekTint: 0,
        lipTint: 0,
      ),
      FaceRetouchLevel.cute => const _FaceRetouchProfile(
        blurRadius: 5,
        skinSoftness: 0.22,
        faceLift: 0.030,
        centerGlow: 0.018,
        edgeShade: 0.022,
        skinBrighten: 0.14,
        cheekPinch: 0.10,
        chinPinch: 0.06,
        cheekTint: 0.44,
        lipTint: 0.34,
      ),
    };
  }
}
