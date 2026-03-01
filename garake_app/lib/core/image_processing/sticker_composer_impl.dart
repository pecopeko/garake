// Renders sticker assets onto filtered image bytes for final export output.
/*
Dependency Memo
- Depends on: sticker_composer.dart and sticker_item.dart contracts.
- Requires methods: rootBundle.load(), image package decode/resize/composite APIs.
- Provides methods: compose().
*/
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../features/editor/domain/entities/sticker_item.dart';
import '../../features/editor/domain/repositories/sticker_composer.dart';

typedef AssetLoader = Future<ByteData> Function(String key);

class StickerComposerImpl implements StickerComposer {
  StickerComposerImpl({AssetLoader? assetLoader})
    : _assetLoader = assetLoader ?? rootBundle.load;

  final AssetLoader _assetLoader;

  @override
  Future<Uint8List> compose(
    Uint8List filtered,
    List<StickerItem> stickers,
    DateTime stampDate,
  ) async {
    final img.Image? base = img.decodeImage(filtered);
    if (base == null) {
      throw const FormatException('Could not decode filtered image.');
    }

    final int reference = min(base.width, base.height);

    for (final StickerItem sticker in stickers) {
      final ByteData data = await _assetLoader(sticker.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final img.Image? decodedSticker = img.decodeImage(bytes);
      if (decodedSticker == null) {
        continue;
      }

      final int target = (reference * 0.18 * sticker.scale)
          .round()
          .clamp(22, (reference * 0.45).round())
          .toInt();
      final img.Image scaled = img.copyResize(
        decodedSticker,
        width: target,
        height: target,
        interpolation: img.Interpolation.nearest,
      );

      final int dstX = (sticker.normalizedOffset.dx * base.width - (target / 2))
          .round();
      final int dstY =
          (sticker.normalizedOffset.dy * base.height - (target / 2)).round();

      img.compositeImage(
        base,
        scaled,
        dstX: dstX.clamp(-target ~/ 2, base.width - 1),
        dstY: dstY.clamp(-target ~/ 2, base.height - 1),
      );
    }

    return Uint8List.fromList(img.encodeJpg(base, quality: 68));
  }
}
