// Defines persistence and sharing gateways for processed JPEG images.
/*
Dependency Memo
- Depends on: save_result.dart for persistence metadata output.
- Requires methods: none.
- Provides methods: saveJpeg(), shareImage().
*/
import 'dart:typed_data';

import '../entities/save_result.dart';

abstract class ExportRepository {
  Future<SaveResult> saveJpeg(Uint8List bytes);

  Future<void> shareImage(Uint8List bytes, {String? text});
}
