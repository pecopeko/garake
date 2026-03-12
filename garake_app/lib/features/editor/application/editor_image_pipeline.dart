// Coordinates initial decode, face detection, and retro rerendering for editor sessions.
/*
Dependency Memo
- Depends on: app_exception.dart, detected_face.dart, face_retouch_level.dart, filter_config.dart, filter_engine.dart, and face_feature_detector.dart.
- Requires methods: detectFaces(), applyGarakeFilter(), image.decodeImage(), image.bakeOrientation().
- Provides methods: loadSessionData(), renderFilteredPreview().
*/
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/entities/detected_face.dart';
import '../domain/entities/face_retouch_level.dart';
import '../domain/entities/filter_config.dart';
import '../domain/repositories/face_feature_detector.dart';
import '../domain/repositories/filter_engine.dart';

class EditorImagePipeline {
  const EditorImagePipeline({
    required FilterEngine filterEngine,
    required FaceFeatureDetector faceFeatureDetector,
    required FilterConfig filterConfig,
  }) : _filterEngine = filterEngine,
       _faceFeatureDetector = faceFeatureDetector,
       _filterConfig = filterConfig;

  final FilterEngine _filterEngine;
  final FaceFeatureDetector _faceFeatureDetector;
  final FilterConfig _filterConfig;

  Future<EditorImageLoadResult> loadSessionData(
    Uint8List inputBytes,
    DateTime stampDate,
  ) async {
    final img.Image? decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      throw AppException(
        AppLocalizations.current.unsupportedImageFormatMessage,
      );
    }
    final img.Image normalized = img.bakeOrientation(decoded);

    final Future<List<DetectedFace>> detectedFacesFuture = _faceFeatureDetector
        .detectFaces(inputBytes)
        .catchError((_) => const <DetectedFace>[]);

    final Uint8List filteredBytes = await renderFilteredPreview(
      inputBytes: inputBytes,
      stampDate: stampDate,
      detectedFaces: const <DetectedFace>[],
      faceRetouchLevel: FaceRetouchLevel.off,
    );

    final List<DetectedFace> detectedFaces = (await detectedFacesFuture)
        .where((DetectedFace face) => face.hasUsableArea)
        .toList(growable: false);

    return EditorImageLoadResult(
      filteredBytes: filteredBytes,
      originalImageSize: Size(
        normalized.width.toDouble(),
        normalized.height.toDouble(),
      ),
      detectedFaces: detectedFaces,
    );
  }

  Future<Uint8List> renderFilteredPreview({
    required Uint8List inputBytes,
    required DateTime stampDate,
    required List<DetectedFace> detectedFaces,
    required FaceRetouchLevel faceRetouchLevel,
  }) {
    return _filterEngine.applyGarakeFilter(
      inputBytes,
      _filterConfig,
      stampDate,
      detectedFaces: detectedFaces,
      faceRetouchLevel: faceRetouchLevel,
    );
  }
}

class EditorImageLoadResult {
  const EditorImageLoadResult({
    required this.filteredBytes,
    required this.originalImageSize,
    required this.detectedFaces,
  });

  final Uint8List filteredBytes;
  final Size originalImageSize;
  final List<DetectedFace> detectedFaces;
}
