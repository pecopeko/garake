// Runs a smoke flow that opens the menu, imports an image, and renders editor canvas.
/*
Dependency Memo
- Depends on: GarakeApp and editor providers for dependency overrides.
- Requires methods: IntegrationTestWidgetsFlutterBinding.ensureInitialized(), tester.tap(), tester.pumpAndSettle().
- Provides methods: main() integration scenario.
*/
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';

import 'package:garake_app/app/app.dart';
import 'package:garake_app/features/editor/application/editor_providers.dart';
import 'package:garake_app/features/editor/domain/entities/filter_config.dart';
import 'package:garake_app/features/editor/domain/entities/save_result.dart';
import 'package:garake_app/features/editor/domain/entities/sticker_item.dart';
import 'package:garake_app/features/editor/domain/repositories/export_repository.dart';
import 'package:garake_app/features/editor/domain/repositories/filter_engine.dart';
import 'package:garake_app/features/editor/domain/repositories/image_source_repository.dart';
import 'package:garake_app/features/editor/domain/repositories/sticker_composer.dart';

class _StubImageSourceRepository implements ImageSourceRepository {
  _StubImageSourceRepository(this.payload);

  final Uint8List payload;

  @override
  Future<Uint8List> pickFromCamera() async => payload;

  @override
  Future<Uint8List> pickFromGallery() async => payload;
}

class _StubFilterEngine implements FilterEngine {
  _StubFilterEngine(this.output);

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

class _StubStickerComposer implements StickerComposer {
  @override
  Future<Uint8List> compose(
    Uint8List filtered,
    List<StickerItem> stickers,
    DateTime stampDate,
  ) async {
    return filtered;
  }
}

class _StubExportRepository implements ExportRepository {
  @override
  Future<SaveResult> saveJpeg(Uint8List bytes) async {
    return SaveResult(
      filePath: '/tmp/integration.jpg',
      createdAt: DateTime(2026, 2, 22),
    );
  }

  @override
  Future<void> shareImage(Uint8List bytes, {String? text}) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and completes menu import flow without crash', (
    WidgetTester tester,
  ) async {
    final img.Image source = img.Image(width: 96, height: 128);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 70, 90, (x + y) % 255, 255);
      }
    }
    final Uint8List bytes = Uint8List.fromList(
      img.encodeJpg(source, quality: 85),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          imageSourceRepositoryProvider.overrideWithValue(
            _StubImageSourceRepository(bytes),
          ),
          filterEngineProvider.overrideWithValue(_StubFilterEngine(bytes)),
          stickerComposerProvider.overrideWithValue(_StubStickerComposer()),
          exportRepositoryProvider.overrideWithValue(_StubExportRepository()),
        ],
        child: const GarakeApp(),
      ),
    );

    expect(find.byKey(const Key('menu-button')), findsOneWidget);
    expect(find.byKey(const Key('stamp-button')), findsOneWidget);
    expect(find.byKey(const Key('save-share-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('アルバムから選ぶ'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('editor-canvas')), findsOneWidget);
  });
}
