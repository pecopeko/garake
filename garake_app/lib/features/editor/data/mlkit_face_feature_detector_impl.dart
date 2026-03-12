// Uses ML Kit to detect faces once and converts them into normalized editor landmarks.
/*
Dependency Memo
- Depends on: face_feature_detector.dart, detected_face.dart, google_mlkit_face_detection, image package normalization helpers, path_provider, and dart:io temp files.
- Requires methods: FaceDetector.processImage(), InputImage.fromFilePath(), image.decodeImage(), image.bakeOrientation(), image.encodeJpg(), getTemporaryDirectory().
- Provides methods: detectFaces(), dispose().
*/
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../domain/entities/detected_face.dart';
import '../domain/repositories/face_feature_detector.dart';

typedef TempDirectoryResolver = Future<Directory> Function();

class MlKitFaceFeatureDetectorImpl implements FaceFeatureDetector {
  MlKitFaceFeatureDetectorImpl({
    TempDirectoryResolver? tempDirectoryResolver,
    FaceDetector? detector,
  }) : _tempDirectoryResolver = tempDirectoryResolver ?? getTemporaryDirectory,
       _detector =
           detector ??
           FaceDetector(
             options: FaceDetectorOptions(
               enableLandmarks: true,
               enableClassification: true,
               minFaceSize: 0.04,
               performanceMode: FaceDetectorMode.accurate,
             ),
           );

  final TempDirectoryResolver _tempDirectoryResolver;
  final FaceDetector _detector;

  @override
  Future<List<DetectedFace>> detectFaces(Uint8List inputBytes) async {
    final _PreparedDetectorImage? prepared = _prepareDetectorImage(inputBytes);
    if (prepared == null) {
      return const <DetectedFace>[];
    }

    final File tempFile = await _writeTempImage(prepared.encodedBytes);
    try {
      final InputImage image = InputImage.fromFilePath(tempFile.path);
      final List<Face> faces = await _detector.processImage(image);
      return faces
          .map((Face face) => _mapFace(face, prepared.imageSize))
          .toList(growable: false);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  @override
  Future<void> dispose() {
    return _detector.close();
  }

  Future<File> _writeTempImage(Uint8List inputBytes) async {
    final Directory directory = await _tempDirectoryResolver();
    final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final File file = File('${directory.path}/garasha_face_$timestamp.jpg');
    return file.writeAsBytes(inputBytes, flush: true);
  }

  // ML Kit に渡す画像形式と向きを固定して検出失敗を減らす。
  _PreparedDetectorImage? _prepareDetectorImage(Uint8List inputBytes) {
    final img.Image? decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      return null;
    }

    final img.Image normalized = img.bakeOrientation(decoded);
    return _PreparedDetectorImage(
      encodedBytes: Uint8List.fromList(img.encodeJpg(normalized, quality: 96)),
      imageSize: Size(
        normalized.width.toDouble(),
        normalized.height.toDouble(),
      ),
    );
  }

  DetectedFace _mapFace(Face face, Size imageSize) {
    final Rect box = face.boundingBox;
    return DetectedFace(
      normalizedBounds: Rect.fromLTWH(
        (box.left / imageSize.width).clamp(0.0, 1.0),
        (box.top / imageSize.height).clamp(0.0, 1.0),
        (box.width / imageSize.width).clamp(0.0, 1.0),
        (box.height / imageSize.height).clamp(0.0, 1.0),
      ),
      leftEye: _normalizeLandmark(
        face.landmarks[FaceLandmarkType.leftEye],
        imageSize,
      ),
      rightEye: _normalizeLandmark(
        face.landmarks[FaceLandmarkType.rightEye],
        imageSize,
      ),
      noseBase: _normalizeLandmark(
        face.landmarks[FaceLandmarkType.noseBase],
        imageSize,
      ),
      bottomMouth: _normalizeLandmark(
        face.landmarks[FaceLandmarkType.bottomMouth],
        imageSize,
      ),
      leftCheek: _normalizeLandmark(
        face.landmarks[FaceLandmarkType.leftCheek],
        imageSize,
      ),
      rightCheek: _normalizeLandmark(
        face.landmarks[FaceLandmarkType.rightCheek],
        imageSize,
      ),
      smileProbability: face.smilingProbability,
    );
  }

  Offset? _normalizeLandmark(FaceLandmark? landmark, Size imageSize) {
    if (landmark == null) {
      return null;
    }
    return Offset(
      (landmark.position.x / imageSize.width).clamp(0.0, 1.0),
      (landmark.position.y / imageSize.height).clamp(0.0, 1.0),
    );
  }
}

class _PreparedDetectorImage {
  const _PreparedDetectorImage({
    required this.encodedBytes,
    required this.imageSize,
  });

  final Uint8List encodedBytes;
  final Size imageSize;
}
