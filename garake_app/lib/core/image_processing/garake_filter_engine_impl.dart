// Applies face retouch, soft film-like tone, grain, edge effects, light artifacts, and date stamp.
/*
Dependency Memo
- Depends on: filter_engine.dart, filter_config.dart, detected_face.dart, and face_retouch_level.dart contracts.
- Requires methods: image package decode/resize/draw/blur/composite/encode APIs.
- Provides methods: applyGarakeFilter().
*/
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../features/editor/domain/entities/detected_face.dart';
import '../../features/editor/domain/entities/face_retouch_level.dart';
import '../../features/editor/domain/entities/filter_config.dart';
import '../../features/editor/domain/repositories/filter_engine.dart';
import 'light_leak_spot.dart';

part 'garake_filter_engine_artifacts.dart';
part 'garake_filter_engine_face_retouch.dart';

class GarakeFilterEngineImpl implements FilterEngine {
  @override
  Future<Uint8List> applyGarakeFilter(
    Uint8List input,
    FilterConfig config,
    DateTime now, {
    List<DetectedFace> detectedFaces = const <DetectedFace>[],
    FaceRetouchLevel faceRetouchLevel = FaceRetouchLevel.off,
  }) async {
    final img.Image? decoded = img.decodeImage(input);
    if (decoded == null) {
      throw const FormatException('Unsupported image format.');
    }

    final int shortSide = min(decoded.width, decoded.height);
    final double downscaleRatio = shortSide > config.downscaleShortSide
        ? config.downscaleShortSide / shortSide
        : 1.0;

    final int workingWidth = max(1, (decoded.width * downscaleRatio).round());
    final int workingHeight = max(1, (decoded.height * downscaleRatio).round());

    img.Image working = img.copyResize(
      decoded,
      width: workingWidth,
      height: workingHeight,
      interpolation: img.Interpolation.average,
    );

    _applyFaceRetouch(working, detectedFaces, faceRetouchLevel);
    _applyToneCurve(working, config);
    _applyColorSeparation(working, config);
    _applySoftening(working, config);
    _applyDualGrain(working, config, now.millisecondsSinceEpoch);
    _applyEdgeTreatment(working, config);
    _applyHalation(working, config);
    _applyLightLeak(working, config, now.millisecondsSinceEpoch + 97);

    working = _applyChromaShift(working, config.chromaShift);
    _drawDateStamp(working, now, config);

    final img.Image output = downscaleRatio < 1
        ? img.copyResize(
            working,
            width: decoded.width,
            height: decoded.height,
            interpolation: img.Interpolation.linear,
          )
        : working;

    return Uint8List.fromList(
      img.encodeJpg(output, quality: config.jpegQuality),
    );
  }

  // Gives shadows a slight lift while compressing highlights for film-like latitude.
  void _applyToneCurve(img.Image image, FilterConfig config) {
    final double shadowLift = config.shadowLift.clamp(0, 0.4);
    final double highlightCompression = config.highlightCompression.clamp(
      0,
      0.4,
    );
    final double toneContrast = config.toneContrast.clamp(0, 0.4);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel p = image.getPixel(x, y);
        final int r = _toneChannel(
          p.r.toInt(),
          shadowLift,
          highlightCompression,
          toneContrast,
        );
        final int g = _toneChannel(
          p.g.toInt(),
          shadowLift,
          highlightCompression,
          toneContrast,
        );
        final int b = _toneChannel(
          p.b.toInt(),
          shadowLift,
          highlightCompression,
          toneContrast,
        );
        image.setPixelRgba(x, y, r, g, b, p.a);
      }
    }
  }

  int _toneChannel(
    int value,
    double shadowLift,
    double highlightCompression,
    double toneContrast,
  ) {
    final double v = value / 255.0;
    final double lifted = (v + shadowLift * pow(1 - v, 2.2)).clamp(0.0, 1.0);
    final double rolled =
        (1 - pow(1 - lifted, 1.0 + highlightCompression).toDouble()).clamp(
          0.0,
          1.0,
        );
    final double contrastGain = 1.0 + toneContrast;
    final double contrasted = (0.5 + (rolled - 0.5) * contrastGain).clamp(
      0.0,
      1.0,
    );
    return (contrasted * 255).round();
  }

  // Adds warm WB offset and split-toning style color cast separation by luminance.
  void _applyColorSeparation(img.Image image, FilterConfig config) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel p = image.getPixel(x, y);
        final double r0 = p.r.toDouble();
        final double g0 = p.g.toDouble();
        final double b0 = p.b.toDouble();
        final double luma = (0.2126 * r0 + 0.7152 * g0 + 0.0722 * b0) / 255.0;

        final double shadowWeight = pow(1 - luma, 1.35).toDouble();
        final double highlightWeight = pow(luma, 1.15).toDouble();

        double r =
            r0 +
            config.whiteBalanceWarmth * 26 +
            config.highlightWarmCast * 28 * highlightWeight;
        double g =
            g0 +
            config.whiteBalanceWarmth * 10 +
            config.shadowGreenCast * 24 * shadowWeight;
        double b = b0 - config.whiteBalanceWarmth * 22;

        r -= config.shadowCyanCast * 6 * shadowWeight;
        g += config.shadowCyanCast * 8 * shadowWeight;
        b += config.shadowCyanCast * 16 * shadowWeight;

        r += config.highlightWarmCast * 6 * highlightWeight;
        g += config.highlightWarmCast * 4 * highlightWeight;
        b -= config.highlightWarmCast * 9 * highlightWeight;

        image.setPixelRgba(x, y, _clamp8(r), _clamp8(g), _clamp8(b), p.a);
      }
    }
  }

  // Removes digital edge harshness with a very light Gaussian blend.
  void _applySoftening(img.Image image, FilterConfig config) {
    if (config.softenMix <= 0 || config.softenSigma <= 0) {
      return;
    }

    final img.Image source = img.Image.from(image);
    final img.Image blurred = img.Image.from(image);
    img.gaussianBlur(blurred, radius: _sigmaToRadius(config.softenSigma));

    final double mix = config.softenMix.clamp(0.0, 1.0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel o = source.getPixel(x, y);
        final img.Pixel b = blurred.getPixel(x, y);
        image.setPixelRgba(
          x,
          y,
          _clamp8(o.r * (1 - mix) + b.r * mix),
          _clamp8(o.g * (1 - mix) + b.g * mix),
          _clamp8(o.b * (1 - mix) + b.b * mix),
          o.a,
        );
      }
    }
  }

  // Builds two grain scales and mixes them to recover texture naturally.
  void _applyDualGrain(img.Image image, FilterConfig config, int seed) {
    final int longSide = max(image.width, image.height);
    final double longSideFactor = longSide / 3000.0;
    final int fineCell = max(
      1,
      (longSideFactor * config.grainFineScale * 3.6).round(),
    );
    final int coarseCell = max(
      2,
      (longSideFactor * config.grainCoarseScale * 8.2).round(),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel p = image.getPixel(x, y);
        final double luma =
            (0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b) / 255.0;
        final double toneMask =
            0.65 + (1 - (luma - 0.5).abs() * 1.8).clamp(0.0, 1.0) * 0.35;

        final double fine = (_hashToSigned(
          x ~/ fineCell,
          y ~/ fineCell,
          seed + 11,
        ));
        final double coarse = (_hashToSigned(
          x ~/ coarseCell,
          y ~/ coarseCell,
          seed + 53,
        ));
        final double grain =
            (fine * config.grainFineStrength +
                coarse * config.grainCoarseStrength) *
            255.0 *
            toneMask;

        image.setPixelRgba(
          x,
          y,
          _clamp8(p.r + grain),
          _clamp8(p.g + grain),
          _clamp8(p.b + grain),
          p.a,
        );
      }
    }
  }

  double _hashToSigned(int x, int y, int seed) {
    final int n = x * 374761393 + y * 668265263 + seed * 700001;
    int t = (n ^ (n >> 13)) * 1274126177;
    t ^= (t >> 16);
    final double normalized = (t & 0x7fffffff) / 0x7fffffff;
    return normalized * 2.0 - 1.0;
  }

  // Applies gentle vignette, edge desaturation, and subtle hue drift.
  void _applyEdgeTreatment(img.Image image, FilterConfig config) {
    final double cx = (image.width - 1) / 2.0;
    final double cy = (image.height - 1) / 2.0;
    final double maxDistance = sqrt(cx * cx + cy * cy);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel p = image.getPixel(x, y);
        final double dx = x - cx;
        final double dy = y - cy;
        final double dist = sqrt(dx * dx + dy * dy) / maxDistance;

        final double edge = _smoothStep(0.45, 1.0, dist);
        final double vignette = 1.0 - config.vignetteStrength * edge;

        double r = p.r * vignette;
        double g = p.g * vignette;
        double b = p.b * vignette;

        final double luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        final double desat = (config.edgeDesaturation * edge).clamp(0.0, 1.0);
        r = r * (1 - desat) + luma * desat;
        g = g * (1 - desat) + luma * desat;
        b = b * (1 - desat) + luma * desat;

        final double shift = (config.edgeHueShift * edge).clamp(0.0, 0.2);
        final double shiftedR = r * (1 - shift) + g * shift;
        final double shiftedG = g * (1 - shift * 0.5) + b * shift * 0.5;
        final double shiftedB = b * (1 - shift) + r * shift;

        image.setPixelRgba(
          x,
          y,
          _clamp8(shiftedR),
          _clamp8(shiftedG),
          _clamp8(shiftedB),
          p.a,
        );
      }
    }
  }

  // Blooms bright areas softly to emulate halation around highlights.
  void _applyHalation(img.Image image, FilterConfig config) {
    if (config.halationStrength <= 0) {
      return;
    }

    final img.Image mask = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel p = image.getPixel(x, y);
        final double luma =
            (0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b) / 255.0;
        final double highlight =
            ((luma - config.halationThreshold) /
                    max(0.01, 1.0 - config.halationThreshold))
                .clamp(0.0, 1.0);
        final int v = (pow(highlight, 1.6) * 255).round();
        mask.setPixelRgba(x, y, v, v, v, 255);
      }
    }

    final int blurRadius = max(
      1,
      (max(image.width, image.height) / 1400).round(),
    );
    img.gaussianBlur(mask, radius: blurRadius);

    const double warmR = 1.0;
    const double warmG = 0.72;
    const double warmB = 0.52;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel p = image.getPixel(x, y);
        final img.Pixel m = mask.getPixel(x, y);
        final double glow = (m.r / 255.0) * config.halationStrength;
        if (glow <= 0) {
          continue;
        }

        final double r = _screen(p.r / 255.0, warmR * glow) * 255.0;
        final double g = _screen(p.g / 255.0, warmG * glow) * 255.0;
        final double b = _screen(p.b / 255.0, warmB * glow) * 255.0;

        image.setPixelRgba(x, y, _clamp8(r), _clamp8(g), _clamp8(b), p.a);
      }
    }
  }
}
