// Describes one interactive sticker placed on the editor canvas.
/*
Dependency Memo
- Depends on: dart:ui Offset for normalized position.
- Requires methods: none.
- Provides methods: StickerItem.copyWith().
*/
import 'dart:ui';

class StickerItem {
  const StickerItem({
    required this.id,
    required this.assetPath,
    required this.normalizedOffset,
    required this.scale,
    required this.selected,
  });

  final String id;
  final String assetPath;
  final Offset normalizedOffset;
  final double scale;
  final bool selected;

  StickerItem copyWith({
    String? id,
    String? assetPath,
    Offset? normalizedOffset,
    double? scale,
    bool? selected,
  }) {
    return StickerItem(
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      normalizedOffset: normalizedOffset ?? this.normalizedOffset,
      scale: scale ?? this.scale,
      selected: selected ?? this.selected,
    );
  }
}
