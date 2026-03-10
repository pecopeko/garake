// Declares the contract for extracting reusable face positions from a picked image.
/*
Dependency Memo
- Depends on: detected_face.dart and dart:typed_data payloads.
- Requires methods: none.
- Provides methods: detectFaces().
*/
import 'dart:typed_data';

import '../entities/detected_face.dart';

abstract class FaceFeatureDetector {
  Future<List<DetectedFace>> detectFaces(Uint8List inputBytes);

  Future<void> dispose();
}
