// Extracts home menu definitions and shell/menu label helpers so the main screen file stays small and focused.
/*
Dependency Memo
- Depends on: editor_controller.dart, editor_state.dart, sticker_item.dart, face_retouch_level.dart, and live_capture_coordinator.dart for view-model inputs.
- Requires methods: EditorController.availableStickerAssets and LiveCaptureCoordinator selection/shell label getters.
- Provides methods: editorHomeActions, buildEditorSelectionLabel(), buildEditorModeLabel(), buildSaveShareKeyLabel(), buildStickerPanelItems(), buildFaceRetouchPanelItems(), buildPhotoEditPanelItems(), buildVideoClipPanelItems().
*/
import '../../../../app/localization/app_localizations.dart';
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

List<HomeAction> buildEditorHomeActions() {
  final AppLocalizations l10n = AppLocalizations.current;
  return <HomeAction>[
    HomeAction(
      iconGlyph: '📷',
      label: l10n.homeTakePhoto,
      kind: HomeActionKind.photoCapture,
    ),
    HomeAction(
      iconGlyph: '🎥',
      label: l10n.homeTakeVideo,
      kind: HomeActionKind.videoCapture,
    ),
    HomeAction(
      iconGlyph: '🖼',
      label: l10n.homeEditPhoto,
      kind: HomeActionKind.galleryEdit,
    ),
  ];
}

String buildEditorSelectionLabel({
  required List<StickerItem> stickers,
  required bool showLiveCapture,
  required LiveCaptureCoordinator liveCapture,
}) {
  final AppLocalizations l10n = AppLocalizations.current;
  if (showLiveCapture) {
    return liveCapture.selectionLabel;
  }

  final int selectedIndex = stickers.indexWhere(
    (StickerItem item) => item.selected,
  );
  if (selectedIndex >= 0) {
    return l10n.stickerSelectionLabel(
      selectedIndex: selectedIndex + 1,
      total: stickers.length,
    );
  }
  return l10n.stickerSelectionLabel(
    selectedIndex: null,
    total: stickers.length,
  );
}

String buildEditorModeLabel({
  required EditorState state,
  required bool showLiveCapture,
  required LiveCaptureCoordinator liveCapture,
}) {
  if (showLiveCapture) {
    return liveCapture.shellModeLabel;
  }
  final AppLocalizations l10n = AppLocalizations.current;
  return state.keypadMode == KeypadMode.move ? l10n.modeMove : l10n.modeScale;
}

String buildSaveShareKeyLabel({
  required bool showLiveCapture,
  required LiveCaptureCoordinator liveCapture,
}) {
  final AppLocalizations l10n = AppLocalizations.current;
  if (!showLiveCapture) {
    return l10n.keySaveShare;
  }
  return liveCapture.canOpenSaveSharePanel ? l10n.keyShare : l10n.keyDisabled;
}

List<String> buildStickerPanelItems() {
  return EditorController.availableStickerAssets
      .map(_buildStickerPanelLabel)
      .toList(growable: false);
}

// asset名を一覧向けの短いラベルへ変換する。
String _buildStickerPanelLabel(String assetPath) {
  final AppLocalizations l10n = AppLocalizations.current;
  final String fileName = assetPath.split('/').last.split('.').first;
  switch (fileName) {
    case 'heart_red':
      return l10n.stickerHeartRed;
    case 'heart_pink':
      return l10n.stickerHeartPink;
    case 'star_yellow':
      return l10n.stickerStarYellow;
    case 'star_orange':
      return l10n.stickerStarOrange;
    case 'sparkle_gold':
      return l10n.stickerSparkleGold;
    case 'sparkle_pink':
      return l10n.stickerSparklePink;
  }
  return fileName.replaceAll('_', ' ');
}

List<String> buildFaceRetouchPanelItems(FaceRetouchLevel currentLevel) {
  final AppLocalizations l10n = AppLocalizations.current;
  return FaceRetouchLevel.values
      .map((FaceRetouchLevel level) {
        final String label = l10n.faceRetouchLabel(enabled: level.isEnabled);
        return level == currentLevel ? '● $label' : label;
      })
      .toList(growable: false);
}

List<String> buildPhotoEditPanelItems(FaceRetouchLevel currentLevel) {
  final AppLocalizations l10n = AppLocalizations.current;
  final String currentLabel = l10n.faceRetouchLabel(
    enabled: currentLevel.isEnabled,
  );
  return <String>[
    '${l10n.faceRetouchMenuLabel} ($currentLabel)',
    l10n.menuSave,
    l10n.menuShare,
    l10n.menuDelete,
  ];
}

List<String> buildVideoClipPanelItems() {
  final AppLocalizations l10n = AppLocalizations.current;
  return <String>[l10n.menuSave, l10n.menuShare, l10n.menuDelete];
}
