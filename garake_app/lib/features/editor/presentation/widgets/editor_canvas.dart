// Renders a fitted photo area and passive sticker overlays controlled only by keypad input.
/*
Dependency Memo
- Depends on: sticker_item.dart and canvas_transform.dart model types.
- Requires methods: onCanvasTransformChanged().
- Provides methods: EditorCanvas.build().
*/
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/entities/canvas_transform.dart';
import '../../domain/entities/sticker_item.dart';
import 'garake_home_screen.dart';

class EditorCanvas extends StatelessWidget {
  const EditorCanvas({
    super.key,
    required this.filteredBytes,
    required this.imageSize,
    required this.stickers,
    required this.onCanvasTransformChanged,
    this.onCameraPressed,
    this.onEditPhotoPressed,
  });

  final Uint8List? filteredBytes;
  final Size? imageSize;
  final List<StickerItem> stickers;
  final ValueChanged<CanvasTransform> onCanvasTransformChanged;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onEditPhotoPressed;

  @override
  Widget build(BuildContext context) {
    // 写真未読み込み時はガラケー風ホーム画面を表示。
    if (filteredBytes == null || imageSize == null) {
      return GarakeHomeScreen(
        onCameraPressed: onCameraPressed,
        onEditPhotoPressed: onEditPhotoPressed,
      );
    }


    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size viewport = constraints.biggest;
        final Rect imageRect = _fitContainRect(viewport, imageSize!);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          onCanvasTransformChanged(
            CanvasTransform(
              viewportSize: viewport,
              imageRectOffset: imageRect.topLeft,
              imageRenderSize: imageRect.size,
            ),
          );
        });

        return Stack(
          key: const Key('editor-canvas'),
          fit: StackFit.expand,
          children: <Widget>[
            const ColoredBox(color: Colors.black),
            Positioned.fromRect(
              rect: imageRect,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.memory(
                      filteredBytes!,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.none,
                    ),
                    IgnorePointer(
                      child: Stack(
                        children: <Widget>[
                          for (final StickerItem sticker in stickers)
                            _StickerOverlay(
                              key: ValueKey<String>(sticker.id),
                              sticker: sticker,
                              canvasSize: imageRect.size,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Rect _fitContainRect(Size viewport, Size image) {
    if (viewport.width <= 0 ||
        viewport.height <= 0 ||
        image.width <= 0 ||
        image.height <= 0) {
      return Rect.zero;
    }
    final double viewportAspect = viewport.width / viewport.height;
    final double imageAspect = image.width / image.height;

    if (imageAspect > viewportAspect) {
      final double width = viewport.width;
      final double height = width / imageAspect;
      final double top = (viewport.height - height) / 2;
      return Rect.fromLTWH(0, top, width, height);
    }

    final double height = viewport.height;
    final double width = height * imageAspect;
    final double left = (viewport.width - width) / 2;
    return Rect.fromLTWH(left, 0, width, height);
  }
}

class _StickerOverlay extends StatelessWidget {
  const _StickerOverlay({
    super.key,
    required this.sticker,
    required this.canvasSize,
  });

  final StickerItem sticker;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    final double baseSize = (canvasSize.shortestSide * 0.16 * sticker.scale)
        .clamp(20, 220)
        .toDouble();
    final double left =
        (sticker.normalizedOffset.dx * canvasSize.width) - baseSize / 2;
    final double top =
        (sticker.normalizedOffset.dy * canvasSize.height) - baseSize / 2;

    return Positioned(
      left: left,
      top: top,
      width: baseSize,
      height: baseSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: sticker.selected
              ? Border.all(color: const Color(0xFFF2DB5F), width: 2)
              : null,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Image.asset(
          sticker.assetPath,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}
