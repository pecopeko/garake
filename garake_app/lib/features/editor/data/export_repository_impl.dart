// Persists JPEG bytes to photo library with fallback and opens iOS share sheet.
/*
Dependency Memo
- Depends on: export_repository.dart and save_result.dart contracts.
- Requires methods: ImageGallerySaver.saveImage(), Permission.photosAddOnly.request(), SharePlus.instance.share().
- Provides methods: saveJpeg(), shareImage().
*/
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities/save_result.dart';
import '../domain/repositories/export_repository.dart';

class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl({Permission? photosPermission, DateTime Function()? now})
    : _photosPermission = photosPermission ?? Permission.photosAddOnly,
      _now = now ?? DateTime.now;

  final Permission _photosPermission;
  final DateTime Function() _now;

  @override
  Future<SaveResult> saveJpeg(Uint8List bytes) async {
    final File file = await _writeTempJpeg(bytes, prefix: 'garake_save');
    final DateTime created = _now();

    final PermissionStatus status = await _photosPermission.request();
    if (!(status.isGranted || status.isLimited || status.isProvisional)) {
      throw const AppException('写真アプリに保存する権限がありません。設定をご確認ください。');
    }

    final dynamic result = await ImageGallerySaver.saveImage(
      bytes,
      quality: 100,
      name: 'garake_${created.millisecondsSinceEpoch}',
      isReturnImagePathOfIOS: true,
    );
    if (!_isSaveSuccess(result)) {
      throw const AppException('写真アプリへの保存に失敗しました。');
    }

    return SaveResult(
      filePath: _extractSavedPath(result) ?? file.path,
      createdAt: created,
    );
  }

  @override
  Future<void> shareImage(Uint8List bytes, {String? text}) async {
    final File file = await _writeTempJpeg(bytes, prefix: 'garake_share');
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: 'image/jpeg')],
        text: text,
        subject: 'ガラケーカメラ',
        // iPadでも共有シートを安定表示するための既定アンカー位置。
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
  }

  Future<File> _writeTempJpeg(Uint8List bytes, {required String prefix}) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String path =
        '${tempDir.path}/${prefix}_${_now().microsecondsSinceEpoch}.jpg';
    final File file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  bool _isSaveSuccess(dynamic result) {
    if (result is Map) {
      final dynamic isSuccess = result['isSuccess'];
      if (isSuccess is bool) {
        return isSuccess;
      }
      if (isSuccess is String) {
        return isSuccess.toLowerCase() == 'true';
      }
    }
    return false;
  }

  String? _extractSavedPath(dynamic result) {
    if (result is Map) {
      final dynamic path = result['filePath'] ?? result['path'];
      if (path is String && path.isNotEmpty) {
        return path;
      }
    }
    return null;
  }
}
