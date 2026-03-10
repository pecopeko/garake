// Defines persistence and sharing gateways for processed JPEG images and recorded videos.
/*
Dependency Memo
- Depends on: save_result.dart for persistence metadata output.
- Requires methods: none.
- Provides methods: saveJpeg(), saveVideoFile(), shareImage(), shareVideoFile().
*/
import 'dart:typed_data';

import '../entities/save_result.dart';

abstract class ExportRepository {
  Future<SaveResult> saveJpeg(Uint8List bytes);

  Future<SaveResult> saveVideoFile(String filePath);

  Future<void> shareImage(Uint8List bytes, {String? text});

  Future<void> shareVideoFile(String filePath, {String? text});
}
