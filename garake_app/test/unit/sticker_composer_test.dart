// Verifies sticker compositor overlays sticker bytes at the requested location.
/*
Dependency Memo
- Depends on: sticker_composer_impl.dart and sticker_item.dart.
- Requires methods: compose().
- Provides methods: main() tests.
*/
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:garake_app/core/image_processing/sticker_composer_impl.dart';
import 'package:garake_app/features/editor/domain/entities/sticker_item.dart';

void main() {
  test('compose draws sticker pixels over filtered base', () async {
    final img.Image base = img.Image(width: 120, height: 120);
    for (int y = 0; y < base.height; y++) {
      for (int x = 0; x < base.width; x++) {
        base.setPixelRgba(x, y, 5, 5, 5, 255);
      }
    }
    final Uint8List filtered = Uint8List.fromList(
      img.encodeJpg(base, quality: 80),
    );

    final img.Image sticker = img.Image(width: 24, height: 24);
    for (int y = 0; y < sticker.height; y++) {
      for (int x = 0; x < sticker.width; x++) {
        sticker.setPixelRgba(x, y, 255, 0, 0, 255);
      }
    }
    final Uint8List stickerBytes = Uint8List.fromList(img.encodePng(sticker));

    final StickerComposerImpl composer = StickerComposerImpl(
      assetLoader: (_) async => ByteData.view(stickerBytes.buffer),
    );

    final Uint8List result = await composer
        .compose(filtered, const <StickerItem>[
          StickerItem(
            id: 's1',
            assetPath: 'assets/stickers/heart_red.png',
            normalizedOffset: Offset(0.5, 0.5),
            scale: 1,
            selected: false,
          ),
        ], DateTime(2026, 2, 22));

    final img.Image? decoded = img.decodeImage(result);
    expect(decoded, isNotNull);
    final img.Pixel p = decoded!.getPixel(60, 60);
    expect(p.r.toInt(), greaterThan(20));
  });
}
