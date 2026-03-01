// Verifies editor controller transitions, sticker editing, deletion, and exports.
/*
Dependency Memo
- Depends on: editor_controller.dart and domain repository interfaces.
- Requires methods: startSession(), addSticker(), updateStickerPosition(), updateStickerScale(), deleteSelectedSticker(), saveCurrentImage(), shareCurrentImage().
- Provides methods: main() tests.
*/
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:garake_app/features/editor/application/editor_controller.dart';
import 'package:garake_app/features/editor/application/editor_state.dart';
import 'package:garake_app/features/editor/domain/entities/filter_config.dart';
import 'package:garake_app/features/editor/domain/entities/save_result.dart';
import 'package:garake_app/features/editor/domain/entities/sticker_item.dart';
import 'package:garake_app/features/editor/domain/enums/image_input_type.dart';
import 'package:garake_app/features/editor/domain/repositories/export_repository.dart';
import 'package:garake_app/features/editor/domain/repositories/filter_engine.dart';
import 'package:garake_app/features/editor/domain/repositories/image_source_repository.dart';
import 'package:garake_app/features/editor/domain/repositories/sticker_composer.dart';

class _FakeImageSourceRepository implements ImageSourceRepository {
  _FakeImageSourceRepository(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> pickFromCamera() async => bytes;

  @override
  Future<Uint8List> pickFromGallery() async => bytes;
}

class _FakeFilterEngine implements FilterEngine {
  _FakeFilterEngine(this.output);

  final Uint8List output;

  @override
  Future<Uint8List> applyGarakeFilter(
    Uint8List input,
    FilterConfig config,
    DateTime now,
  ) async {
    return output;
  }
}

class _FakeStickerComposer implements StickerComposer {
  _FakeStickerComposer(this.output);

  final Uint8List output;
  int callCount = 0;

  @override
  Future<Uint8List> compose(
    Uint8List filtered,
    List<StickerItem> stickers,
    DateTime stampDate,
  ) async {
    callCount += 1;
    return output;
  }
}

class _FakeExportRepository implements ExportRepository {
  int saveCount = 0;
  int shareCount = 0;

  @override
  Future<SaveResult> saveJpeg(Uint8List bytes) async {
    saveCount += 1;
    return SaveResult(
      filePath: '/tmp/garake.jpg',
      createdAt: DateTime(2026, 2, 22),
    );
  }

  @override
  Future<void> shareImage(Uint8List bytes, {String? text}) async {
    shareCount += 1;
  }
}

Uint8List _createJpeg({required int width, required int height}) {
  final img.Image source = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      source.setPixelRgba(
        x,
        y,
        (x * 9) % 255,
        (y * 7) % 255,
        (x + y) % 255,
        255,
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(source, quality: 85));
}

void main() {
  test(
    'startSession loads filtered image and stores source dimensions',
    () async {
      final Uint8List input = _createJpeg(width: 60, height: 90);
      final Uint8List filtered = _createJpeg(width: 60, height: 90);

      final EditorController controller = EditorController(
        imageSourceRepository: _FakeImageSourceRepository(input),
        filterEngine: _FakeFilterEngine(filtered),
        stickerComposer: _FakeStickerComposer(filtered),
        exportRepository: _FakeExportRepository(),
        filterConfig: FilterConfig.v1,
        now: () => DateTime(2026, 2, 22),
      );

      await controller.startSession(ImageInputType.gallery);

      expect(controller.state.status, EditorStatus.ready);
      expect(controller.state.session, isNotNull);
      expect(controller.state.session!.filteredBytes, filtered);
      expect(controller.state.session!.originalImageSize, const Size(60, 90));
    },
  );

  test(
    'sticker operations and save/share trigger downstream repositories',
    () async {
      final Uint8List input = _createJpeg(width: 90, height: 90);
      final Uint8List filtered = _createJpeg(width: 90, height: 90);
      final _FakeStickerComposer composer = _FakeStickerComposer(filtered);
      final _FakeExportRepository export = _FakeExportRepository();

      final EditorController controller = EditorController(
        imageSourceRepository: _FakeImageSourceRepository(input),
        filterEngine: _FakeFilterEngine(filtered),
        stickerComposer: composer,
        exportRepository: export,
        filterConfig: FilterConfig.v1,
        now: () => DateTime(2026, 2, 22),
      );

      await controller.startSession(ImageInputType.camera);
      controller.addSticker(EditorController.availableStickerAssets.first);
      final String stickerId = controller.state.session!.stickers.first.id;

      controller.updateStickerPosition(stickerId, const Offset(0.84, 0.66));
      controller.updateStickerScale(stickerId, 1.75);
      controller.deleteSelectedSticker();

      expect(controller.state.session!.stickers, isEmpty);

      controller.addSticker(EditorController.availableStickerAssets.first);
      await controller.saveCurrentImage();
      await controller.shareCurrentImage();

      expect(composer.callCount, 2);
      expect(export.saveCount, 1);
      expect(export.shareCount, 1);
    },
  );
}
