// Extracts home menu definitions and shell/menu label helpers so the main screen file stays small and focused.
/*
Dependency Memo
- Depends on: editor_controller.dart, editor_state.dart, sticker_item.dart, face_retouch_level.dart, and live_capture_coordinator.dart for view-model inputs.
- Requires methods: EditorController.availableStickerAssets and LiveCaptureCoordinator selection/shell label getters.
- Provides methods: editorHomeActions, buildEditorSelectionLabel(), buildEditorModeLabel(), buildSaveShareKeyLabel(), buildStickerPanelItems(), buildFaceRetouchPanelItems(), buildPhotoEditPanelItems().
*/
import '../../application/editor_controller.dart';
import '../../application/editor_state.dart';
import '../../domain/entities/face_retouch_level.dart';
import '../../domain/entities/sticker_item.dart';
import '../live_capture/live_capture_coordinator.dart';

enum HomeActionKind { photoCapture, videoCapture, galleryEdit }

class HomeAction {
  const HomeAction({
    required this.iconGlyph,
    required this.label,
    required this.kind,
  });

  final String iconGlyph;
  final String label;
  final HomeActionKind kind;
}

const List<HomeAction> editorHomeActions = <HomeAction>[
  HomeAction(
    iconGlyph: '📷',
    label: '写真を撮る',
    kind: HomeActionKind.photoCapture,
  ),
  HomeAction(
    iconGlyph: '🎥',
    label: '動画を撮る',
    kind: HomeActionKind.videoCapture,
  ),
  HomeAction(
    iconGlyph: '🖼',
    label: '写真を編集する',
    kind: HomeActionKind.galleryEdit,
  ),
];

String buildEditorSelectionLabel({
  required List<StickerItem> stickers,
  required bool showLiveCapture,
  required LiveCaptureCoordinator liveCapture,
}) {
  if (showLiveCapture) {
    return liveCapture.selectionLabel;
  }

  final int selectedIndex = stickers.indexWhere(
    (StickerItem item) => item.selected,
  );
  if (selectedIndex >= 0) {
    return 'ST:${selectedIndex + 1}/${stickers.length}';
  }
  if (stickers.isEmpty) {
    return 'ST:0/0';
  }
  return 'ST:None/${stickers.length}';
}

String buildEditorModeLabel({
  required EditorState state,
  required bool showLiveCapture,
  required LiveCaptureCoordinator liveCapture,
}) {
  if (showLiveCapture) {
    return liveCapture.shellModeLabel;
  }
  return state.keypadMode == KeypadMode.move ? 'MOVE' : 'SCALE';
}

String buildSaveShareKeyLabel({
  required bool showLiveCapture,
  required LiveCaptureCoordinator liveCapture,
}) {
  if (!showLiveCapture) {
    return '保存/シェア';
  }
  return liveCapture.canOpenSaveSharePanel ? '保存/シェア' : '---';
}

List<String> buildStickerPanelItems() {
  return EditorController.availableStickerAssets
      .asMap()
      .entries
      .map((MapEntry<int, String> entry) => 'スタンプ ${entry.key + 1}')
      .toList(growable: false);
}

List<String> buildFaceRetouchPanelItems(FaceRetouchLevel currentLevel) {
  return FaceRetouchLevel.values
      .map(
        (FaceRetouchLevel level) => level == currentLevel
            ? '● ${level.menuLabel}'
            : level.menuLabel,
      )
      .toList(growable: false);
}

List<String> buildPhotoEditPanelItems(FaceRetouchLevel currentLevel) {
  return <String>[
    '顔補正 (${currentLevel.menuLabel})',
    '保存する',
    'シェアする',
    '削除',
  ];
}
