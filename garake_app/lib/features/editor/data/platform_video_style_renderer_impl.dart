// Calls platform video processing so recordings can be softened and recompressed after capture.
/*
Dependency Memo
- Depends on: app_exception.dart for user-facing failures and video_style_renderer.dart for the abstraction.
- Requires methods: MethodChannel.invokeMethod() and Platform.isIOS.
- Provides methods: renderDisposableCameraVideo().
*/
import 'dart:io';

import 'package:flutter/services.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/repositories/video_style_renderer.dart';

class PlatformVideoStyleRendererImpl implements VideoStyleRenderer {
  static const MethodChannel _channel = MethodChannel(
    'garake/video_style_renderer',
  );

  @override
  Future<String> renderDisposableCameraVideo(String inputPath) async {
    final AppLocalizations l10n = AppLocalizations.current;
    if (!Platform.isIOS) {
      return inputPath;
    }

    try {
      final String? outputPath = await _channel.invokeMethod<String>(
        'renderDisposableCameraVideo',
        <String, Object?>{'inputPath': inputPath},
      );
      if (outputPath == null || outputPath.isEmpty) {
        throw AppException(l10n.videoResultMissingMessage);
      }
      return outputPath;
    } on PlatformException catch (error) {
      throw AppException(error.message ?? l10n.videoRenderFailedMessage);
    }
  }
}
