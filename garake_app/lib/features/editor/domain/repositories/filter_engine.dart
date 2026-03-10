// Defines the contract for converting a raw image to Garake style output with optional face retouch.
/*
Dependency Memo
- Depends on: filter_config.dart, detected_face.dart, and face_retouch_level.dart for tuning and beauty input.
- Requires methods: none.
- Provides methods: applyGarakeFilter().
*/
import 'dart:typed_data';

import '../entities/detected_face.dart';
import '../entities/face_retouch_level.dart';
import '../entities/filter_config.dart';

abstract class FilterEngine {
  Future<Uint8List> applyGarakeFilter(
    Uint8List input,
    FilterConfig config,
    DateTime now, {
    List<DetectedFace> detectedFaces = const <DetectedFace>[],
    FaceRetouchLevel faceRetouchLevel = FaceRetouchLevel.off,
  });
}
