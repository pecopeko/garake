// Persists processed photos and recorded videos to the gallery and share sheet.
/*
Dependency Memo
- Depends on: export_repository.dart and save_result.dart contracts.
- Requires methods: ImageGallerySaver.saveImage(), saveFile(), Permission.photosAddOnly.request(), SharePlus.instance.share().
- Provides methods: saveJpeg(), saveVideoFile(), shareImage(), shareVideoFile().
*/
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/localization/app_localizations.dart';
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
    final AppLocalizations l10n = AppLocalizations.current;
    final File file = await _writeTempJpeg(bytes, prefix: 'garasha_save');
    final DateTime created = _now();

    final PermissionStatus status = await _photosPermission.request();
    if (!(status.isGranted || status.isLimited || status.isProvisional)) {
      throw AppException(l10n.savePermissionDeniedMessage);
    }

    final dynamic result = await ImageGallerySaver.saveImage(
      bytes,
      quality: 100,
      name: '${l10n.exportFileStem}_${created.millisecondsSinceEpoch}',
      isReturnImagePathOfIOS: true,
    );
    if (!_isSaveSuccess(result)) {
      throw AppException(l10n.savePhotoFailedMessage);
    }

    return SaveResult(
      filePath: _extractSavedPath(result) ?? file.path,
      createdAt: created,
    );
  }

  @override
  Future<SaveResult> saveVideoFile(String filePath) async {
    final AppLocalizations l10n = AppLocalizations.current;
    final File sourceFile = File(filePath);
    if (!await sourceFile.exists()) {
      throw AppException(l10n.saveVideoMissingMessage);
    }

    final DateTime created = _now();
    final PermissionStatus status = await _photosPermission.request();
    if (!(status.isGranted || status.isLimited || status.isProvisional)) {
      throw AppException(l10n.savePermissionDeniedMessage);
    }

    final dynamic result = await ImageGallerySaver.saveFile(
      filePath,
      name: '${l10n.exportFileStem}_${created.millisecondsSinceEpoch}',
      isReturnPathOfIOS: true,
    );
    if (!_isSaveSuccess(result)) {
      throw AppException(l10n.saveVideoFailedMessage);
    }

    return SaveResult(
      filePath: _extractSavedPath(result) ?? filePath,
      createdAt: created,
    );
  }

  @override
  Future<void> shareImage(Uint8List bytes, {String? text}) async {
    final AppLocalizations l10n = AppLocalizations.current;
    final File file = await _writeTempJpeg(bytes, prefix: 'garasha_share');
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: 'image/jpeg')],
        text: text,
        subject: l10n.shareSubject,
        // iPadでも共有シートを安定表示するための既定アンカー位置。
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
  }

  @override
  Future<void> shareVideoFile(String filePath, {String? text}) async {
    final AppLocalizations l10n = AppLocalizations.current;
    final File file = File(filePath);
    if (!await file.exists()) {
      throw AppException(l10n.shareVideoMissingMessage);
    }

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: _videoMimeType(file.path))],
        text: text,
        subject: l10n.shareSubject,
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

  String _videoMimeType(String filePath) {
    final String lowerPath = filePath.toLowerCase();
    if (lowerPath.endsWith('.mov')) {
      return 'video/quicktime';
    }
    return 'video/mp4';
  }
}
