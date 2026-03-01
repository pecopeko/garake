// Defines final image composition by overlaying sticker assets on filtered bytes.
/*
Dependency Memo
- Depends on: sticker_item.dart for placement and scale data.
- Requires methods: none.
- Provides methods: compose().
*/
import 'dart:typed_data';

import '../entities/sticker_item.dart';

abstract class StickerComposer {
  Future<Uint8List> compose(
    Uint8List filtered,
    List<StickerItem> stickers,
    DateTime stampDate,
  );
}
