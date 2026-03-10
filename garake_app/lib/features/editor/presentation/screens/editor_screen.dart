// Hosts the editor shell and in-app photo capture without a separate home screen.
/*
Dependency Memo
- Depends on: editor controller provider, camera.dart, and Garake shell/canvas/menu widgets.
- Requires methods: availableCameras(), CameraController.initialize(), CameraController.takePicture(), EditorController.startSession(), EditorController.startSessionFromBytes(), addSticker(), deleteSelectedSticker(), onArrowUp(), onArrowDown(), onArrowLeft(), onArrowRight(), onOkPressed(), saveCurrentImage(), shareCurrentImage().
- Provides methods: EditorScreen.build().
*/
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/editor_controller.dart';
import '../../application/editor_providers.dart';
import '../../application/editor_state.dart';
import '../../domain/entities/face_retouch_level.dart';
import '../../domain/entities/sticker_item.dart';
import '../../domain/enums/image_input_type.dart';
import '../widgets/editor_canvas.dart';
import '../widgets/garake_menu.dart';
import '../widgets/garake_shell.dart';
import '../widgets/live_camera_preview.dart';

part 'editor_screen_camera.dart';

enum _PanelMode { none, sticker, faceRetouch, saveShare }

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  static const List<String> _saveShareItems = <String>['保存する', 'シェアする', '削除'];

  _PanelMode _panelMode = _PanelMode.none;
  int _panelIndex = 0;
  int _sourceSelectionIndex = 0;
  bool _isLiveCameraMode = false;
  bool _isInitializingCamera = false;
  bool _isCapturing = false;
  String? _cameraErrorMessage;
  String? _systemMessage;
  Timer? _systemMessageTimer;
  CameraController? _liveCameraController;

  @override
  void dispose() {
    _systemMessageTimer?.cancel();
    final CameraController? controller = _liveCameraController;
    _liveCameraController = null;
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EditorState>(editorControllerProvider, (
      EditorState? previous,
      EditorState next,
    ) {
      _handleStateMessages(this, previous, next);
    });

    final EditorState state = ref.watch(editorControllerProvider);
    final EditorController controller = ref.read(
      editorControllerProvider.notifier,
    );
    final List<StickerItem> stickers =
        state.session?.stickers ?? const <StickerItem>[];
    final bool showLiveCamera = _isLiveCameraMode;
    final bool shellBusy =
        state.isBusy || _isInitializingCamera || _isCapturing;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A14),
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: GarakeShell(
          isBusy: shellBusy,
          photoLoaded: showLiveCamera || state.hasSession,
          modeLabel: _modeLabel(state, showLiveCamera),
          selectionLabel: _selectionLabel(stickers, showLiveCamera, state),
          menuWidget: _panelMode == _PanelMode.none
              ? null
              : GarakeMenu(
                  title: _panelTitle,
                  items: _panelItems,
                  selectedIndex: _panelIndex,
                  onUpPressed: () => _movePanelCursor(-1),
                  onDownPressed: () => _movePanelCursor(1),
                  onOkPressed: () => _handleOk(controller),
                ),
          menuKeyLabel: showLiveCamera
              ? '入力切替'
              : state.hasSession
              ? 'ホーム'
              : '---',
          stampKeyLabel: showLiveCamera
              ? '撮影'
              : state.hasSession
              ? 'スタンプ'
              : '---',
          saveShareKeyLabel: showLiveCamera
              ? '---'
              : state.hasSession
              ? '保存/シェア'
              : '---',
          systemMessage: _systemMessage,
          onMenuPressed: () => _handleMenuPress(state),
          onStampPressed: () => _handleStampPress(controller, state),
          onSaveSharePressed: () => _handleSaveSharePress(state),
          onUpPressed: () => _handleArrow(controller, state, up: true),
          onDownPressed: () => _handleArrow(controller, state, down: true),
          onLeftPressed: () => _handleArrow(controller, state, left: true),
          onRightPressed: () => _handleArrow(controller, state, right: true),
          onOkPressed: () => _handleOk(controller),
          preview: showLiveCamera
              ? LiveCameraPreview(
                  controller: _liveCameraController,
                  isInitializing: _isInitializingCamera,
                  errorMessage: _cameraErrorMessage,
                  statusLabel: _cameraErrorMessage == null ? 'PHOTO' : 'ERROR',
                  hintLabel: _isCapturing ? '撮影中...' : 'OKで撮影',
                )
              : EditorCanvas(
                  filteredBytes: state.session?.filteredBytes,
                  imageSize: state.session?.originalImageSize,
                  stickers: stickers,
                  selectedSourceIndex: _sourceSelectionIndex,
                  onCanvasTransformChanged: controller.updateCanvasTransform,
                  onCameraPressed: () => _enterLiveCameraMode(this),
                  onEditPhotoPressed: () =>
                      controller.startSession(ImageInputType.gallery),
                ),
        ),
      ),
    );
  }

  String _selectionLabel(
    List<StickerItem> stickers,
    bool showLiveCamera,
    EditorState state,
  ) {
    if (showLiveCamera) {
      return _cameraErrorMessage == null ? 'SHOT' : 'ERR';
    }
    if (!state.hasSession) {
      return '${_sourceSelectionIndex + 1}/2';
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

  String _modeLabel(EditorState state, bool showLiveCamera) {
    if (showLiveCamera) {
      return 'CAM';
    }
    if (!state.hasSession) {
      return 'READY';
    }
    return state.keypadMode == KeypadMode.move ? 'MOVE' : 'SCALE';
  }

  String get _panelTitle {
    switch (_panelMode) {
      case _PanelMode.sticker:
        return 'スタンプ追加';
      case _PanelMode.faceRetouch:
        return '顔補正';
      case _PanelMode.saveShare:
        return '編集メニュー';
      case _PanelMode.none:
        return '';
    }
  }

  List<String> get _panelItems {
    final FaceRetouchLevel currentLevel =
        ref.read(editorControllerProvider).session?.faceRetouchLevel ??
        FaceRetouchLevel.off;
    switch (_panelMode) {
      case _PanelMode.sticker:
        return EditorController.availableStickerAssets
            .asMap()
            .entries
            .map((MapEntry<int, String> entry) => 'スタンプ ${entry.key + 1}')
            .toList(growable: false);
      case _PanelMode.faceRetouch:
        return FaceRetouchLevel.values
            .map(
              (FaceRetouchLevel level) => level == currentLevel
                  ? '● ${level.menuLabel}'
                  : level.menuLabel,
            )
            .toList(growable: false);
      case _PanelMode.saveShare:
        return <String>['顔補正 (${currentLevel.menuLabel})', ..._saveShareItems];
      case _PanelMode.none:
        return const <String>[];
    }
  }

  Future<void> _handleMenuPress(EditorState state) async {
    if (_panelMode != _PanelMode.none) {
      _closePanel();
      return;
    }
    if (_isLiveCameraMode) {
      await _leaveLiveCameraMode(this);
      return;
    }
    if (!state.hasSession) {
      return;
    }
  }

  Future<void> _handleStampPress(
    EditorController controller,
    EditorState state,
  ) async {
    if (_isLiveCameraMode) {
      await _captureFromLiveCamera(this, controller);
      return;
    }
    if (!state.hasSession) {
      return;
    }
    _openPanel(_PanelMode.sticker);
  }

  void _handleSaveSharePress(EditorState state) {
    if (_isLiveCameraMode || !state.hasSession) {
      return;
    }
    _openPanel(_PanelMode.saveShare);
  }

  void _handleArrow(
    EditorController controller,
    EditorState state, {
    bool up = false,
    bool down = false,
    bool left = false,
    bool right = false,
  }) {
    if (_panelMode != _PanelMode.none) {
      if (up) {
        _movePanelCursor(-1);
      } else if (down) {
        _movePanelCursor(1);
      }
      return;
    }

    if (_isLiveCameraMode) {
      return;
    }

    if (!state.hasSession) {
      setState(() {
        _sourceSelectionIndex = _sourceSelectionIndex == 0 ? 1 : 0;
      });
      return;
    }

    if (up) {
      controller.onArrowUp();
    } else if (down) {
      controller.onArrowDown();
    } else if (left) {
      controller.onArrowLeft();
    } else if (right) {
      controller.onArrowRight();
    }
  }

  Future<void> _handleOk(EditorController controller) async {
    if (_panelMode == _PanelMode.none && _isLiveCameraMode) {
      await _captureFromLiveCamera(this, controller);
      return;
    }

    if (_panelMode == _PanelMode.none) {
      final EditorState state = ref.read(editorControllerProvider);
      if (!state.hasSession) {
        if (_sourceSelectionIndex == 0) {
          await _enterLiveCameraMode(this);
        } else {
          await controller.startSession(ImageInputType.gallery);
        }
        return;
      }
      controller.onOkPressed();
      return;
    }

    if (_panelMode == _PanelMode.sticker) {
      final String asset = EditorController.availableStickerAssets[_panelIndex];
      _closePanel();
      controller.addSticker(asset);
      return;
    }

    if (_panelMode == _PanelMode.faceRetouch) {
      final FaceRetouchLevel level = FaceRetouchLevel.values[_panelIndex];
      _closePanel();
      await controller.updateFaceRetouchLevel(level);
      return;
    }

    final int selected = _panelIndex;
    if (selected == 0) {
      final FaceRetouchLevel currentLevel =
          ref.read(editorControllerProvider).session?.faceRetouchLevel ??
          FaceRetouchLevel.off;
      _openPanel(
        _PanelMode.faceRetouch,
        initialIndex: FaceRetouchLevel.values.indexOf(currentLevel),
      );
    } else if (selected == 1) {
      _closePanel();
      await controller.saveCurrentImage();
    } else if (selected == 2) {
      _closePanel();
      await controller.shareCurrentImage();
    } else {
      _closePanel();
      controller.deleteSelectedSticker();
    }
  }

  void _openPanel(_PanelMode mode, {int initialIndex = 0}) {
    setState(() {
      _panelMode = mode;
      _panelIndex = initialIndex;
    });
  }

  void _closePanel() {
    setState(() {
      _panelMode = _PanelMode.none;
      _panelIndex = 0;
    });
  }

  void _movePanelCursor(int delta) {
    final int length = _panelItems.length;
    if (length == 0) {
      return;
    }
    setState(() {
      _panelIndex = (_panelIndex + delta) % length;
      if (_panelIndex < 0) {
        _panelIndex += length;
      }
    });
  }

  void _applyUiUpdate(VoidCallback update) {
    setState(update);
  }
}
