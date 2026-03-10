// Verifies integrated home/editor UI and in-place gallery transition.
/*
Dependency Memo
- Depends on: app.dart and editor providers for dependency overrides.
- Requires methods: tester.tap(), tester.pumpAndSettle().
- Provides methods: main() widget tests.
*/
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

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
      filePath: '/tmp/test.jpg',
      createdAt: DateTime(2026, 2, 22),
    );
  }

  @override
  Future<SaveResult> saveVideoFile(String filePath) async {
    return SaveResult(filePath: filePath, createdAt: DateTime(2026, 2, 22));
  }

  @override
  Future<void> shareImage(Uint8List bytes, {String? text}) async {}

  @override
  Future<void> shareVideoFile(String filePath, {String? text}) async {}
}

void main() {
  late Uint8List imageBytes;

  setUpAll(() {
    final img.Image source = img.Image(width: 84, height: 126);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 50, 80, 100, 255);
      }
    }
    imageBytes = Uint8List.fromList(img.encodeJpg(source, quality: 80));
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // ガラケーUIはスマホ縦画面を想定しているのでテスト用ビューポートを設定。
    tester.view.physicalSize = const Size(1170, 2532); // iPhone 14 Pro相当
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          imageSourceRepositoryProvider.overrideWithValue(
            _StubImageSourceRepository(imageBytes),
          ),
          filterEngineProvider.overrideWithValue(_StubFilterEngine(imageBytes)),
          stickerComposerProvider.overrideWithValue(_StubStickerComposer()),
          exportRepositoryProvider.overrideWithValue(_StubExportRepository()),
        ],
        child: const GarakeApp(),
      ),
    );
  }

  testWidgets('initial view renders home screen with action items', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await tester.pump();

    // ホーム画面のラベルとアクション項目が表示されること。
    // modeLabelとselectionLabelは結合表示されるため textContaining を使用。
    expect(find.textContaining('HOME'), findsOneWidget);
    expect(find.text('写真を撮る'), findsWidgets);
    expect(find.text('写真を編集する'), findsWidgets);
  });

  testWidgets('selecting gallery from home transitions to editor in-place', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await tester.pump();

    // 「写真を編集する」ボタン（save-share-button）をタップしてギャラリーへ。
    await tester.tap(find.byKey(const Key('save-share-button')));
    await tester.pumpAndSettle();

    // エディターモードに切り替わり、キャンバスが表示されること。
    expect(find.byKey(const Key('editor-canvas')), findsOneWidget);
    // push遷移ではないのでHOMEラベルは消えているはず。
    expect(find.text('HOME'), findsNothing);
  });
}
