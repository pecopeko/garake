// Hosts the editor shell plus in-app photo and disposable-camera video capture so the garake flow stays on one screen.
/*
Dependency Memo
- Depends on: editor controller/provider state, live_capture_coordinator.dart, and Garake shell/canvas/menu widgets.
- Requires methods: EditorController.startSession(), startSessionFromBytes(), returnToHome(), addSticker(), deleteSelectedSticker(), onArrowUp(), onArrowDown(), onArrowLeft(), onArrowRight(), onOkPressed(), saveCurrentImage(), shareCurrentImage(), clearMessages() and LiveCaptureCoordinator enter/leave/toggleLensDirection()/takePhoto()/startVideoRecording()/stopVideoRecording()/saveRecordedVideo()/shareRecordedVideo()/deleteRecordedVideo().
- Provides methods: EditorScreen.build().
*/
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../application/editor_controller.dart';
import '../../application/editor_providers.dart';
import '../../application/editor_state.dart';
import '../../domain/entities/face_retouch_level.dart';
import '../../domain/entities/sticker_item.dart';
import '../../domain/enums/image_input_type.dart';
import '../live_capture/live_capture_coordinator.dart';
import '../widgets/editor_canvas.dart';
import '../widgets/garake_menu.dart';
import '../widgets/garake_shell.dart';
import '../widgets/live_camera_preview.dart';
import 'editor_screen_support.dart';

part 'editor_screen_camera.dart';

enum _PanelMode { none, sticker, faceRetouch, saveShare }

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  _PanelMode _panelMode = _PanelMode.none;
  int _panelIndex = 0;
  int _sourceSelectionIndex = 0;
  bool _isLiveCaptureActionBusy = false;
  String? _liveCaptureBusyLabel;
  String? _systemMessage;
  Timer? _systemMessageTimer;
  late final LiveCaptureCoordinator _liveCapture;

  @override
  void initState() {
    super.initState();
    _liveCapture = LiveCaptureCoordinator(
      exportRepository: ref.read(exportRepositoryProvider),
      videoStyleRenderer: ref.read(videoStyleRendererProvider),
    );
  }

  @override
  void dispose() {
    _systemMessageTimer?.cancel();
    unawaited(_liveCapture.leave());
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
    final AppLocalizations l10n = context.l10n;
    final List<HomeAction> homeActions = buildEditorHomeActions();
    final List<StickerItem> stickers =
        state.session?.stickers ?? const <StickerItem>[];
    final bool showLiveCapture = _liveCapture.isActive;
    final bool shellBusy =
        state.isBusy ||
        _liveCapture.isInitializing ||
        _liveCapture.isCapturingStill ||
        _isLiveCaptureActionBusy;
    final String? busyLabel = _busyLabel(state);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A14),
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: GarakeShell(
          isBusy: shellBusy,
          busyLabel: busyLabel,
          photoLoaded: showLiveCapture || state.hasSession,
          modeLabel: _modeLabel(state, showLiveCapture),
          selectionLabel: _selectionLabel(
            stickers,
            showLiveCapture,
            state,
            homeActions.length,
          ),
          modeToggleLabel: _liveCapture.lensToggleLabel,
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
          menuKeyLabel: showLiveCapture
              ? l10n.keyBack
              : state.hasSession
              ? l10n.keyHome
              : l10n.keyDisabled,
          stampKeyLabel: showLiveCapture
              ? _liveCapture.primaryActionLabel
              : state.hasSession
              ? l10n.keySticker
              : l10n.keyDisabled,
          decorateKeyLabel: showLiveCapture
              ? (_liveCapture.canOpenSaveSharePanel
                    ? l10n.keySave
                    : l10n.keyDisabled)
              : state.hasSession
              ? l10n.keyDecorate
              : l10n.keyDisabled,
          saveShareKeyLabel: showLiveCapture
              ? buildSaveShareKeyLabel(
                  showLiveCapture: true,
                  liveCapture: _liveCapture,
                )
              : state.hasSession
              ? l10n.keySaveShare
              : l10n.keyDisabled,
          systemMessage: _systemMessage,
          onModeTogglePressed: () => _handleModeTogglePress(state),
          onMenuPressed: () => _handleMenuPress(state),
          onStampPressed: () => _handleStampPress(controller, state),
          onSaveSharePressed: () => _handleSaveSharePress(state),
          onUpPressed: () => _handleArrow(controller, state, up: true),
          onDownPressed: () => _handleArrow(controller, state, down: true),
          onLeftPressed: () => _handleArrow(controller, state, left: true),
          onRightPressed: () => _handleArrow(controller, state, right: true),
          onOkPressed: () => _handleOk(controller),
          preview: showLiveCapture
              ? LiveCameraPreview(
                  controller: _liveCapture.controller,
                  isInitializing: _liveCapture.isInitializing,
                  errorMessage: _liveCapture.errorMessage,
                  statusLabel: _liveCapture.overlayStatusLabel,
                  hintLabel: _liveCapture.overlayHintLabel,
                )
              : EditorCanvas(
                  filteredBytes: state.session?.filteredBytes,
                  imageSize: state.session?.originalImageSize,
                  stickers: stickers,
                  showSelectedStickerFrame: state.keypadMode == KeypadMode.move,
                  selectedSourceIndex: _sourceSelectionIndex,
                  onCanvasTransformChanged: controller.updateCanvasTransform,
                  onCameraPressed: () =>
                      _enterLiveCaptureMode(this, LiveCaptureMode.photo),
                  onVideoPressed: () =>
                      _enterLiveCaptureMode(this, LiveCaptureMode.video),
                  onEditPhotoPressed: () =>
                      controller.startSession(ImageInputType.gallery),
                ),
        ),
      ),
    );
  }

  String _selectionLabel(
    List<StickerItem> stickers,
    bool showLiveCapture,
    EditorState state,
    int homeActionCount,
  ) {
    if (!showLiveCapture && !state.hasSession) {
      return '${_sourceSelectionIndex + 1}/$homeActionCount';
    }
    return buildEditorSelectionLabel(
      stickers: stickers,
      showLiveCapture: showLiveCapture,
      liveCapture: _liveCapture,
    );
  }

  String _modeLabel(EditorState state, bool showLiveCapture) {
    if (!showLiveCapture && !state.hasSession) {
      return AppLocalizations.current.modeReady;
    }
    return buildEditorModeLabel(
      state: state,
      showLiveCapture: showLiveCapture,
      liveCapture: _liveCapture,
    );
  }

  String? _busyLabel(EditorState state) {
    final AppLocalizations l10n = AppLocalizations.current;
    if (_liveCapture.isInitializing) {
      return _liveCapture.isVideoMode
          ? l10n.busyOpeningVideoCamera
          : l10n.busyOpeningCamera;
    }
    if (_liveCapture.isCapturingStill) {
      return l10n.busyReadingCapturedPhoto;
    }
    if (_isLiveCaptureActionBusy) {
      return _liveCaptureBusyLabel ?? l10n.busyProcessing;
    }
    if (state.isBusy) {
      return state.busyMessage ?? l10n.busyLoading;
    }
    return null;
  }

  String get _panelTitle {
    final AppLocalizations l10n = AppLocalizations.current;
    switch (_panelMode) {
      case _PanelMode.sticker:
        return l10n.panelTitleAddSticker;
      case _PanelMode.faceRetouch:
        return l10n.panelTitleFaceRetouch;
      case _PanelMode.saveShare:
        return _liveCapture.canOpenSaveSharePanel
            ? l10n.panelTitleVideoMenu
            : l10n.panelTitleEditMenu;
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
        return buildStickerPanelItems();
      case _PanelMode.faceRetouch:
        return buildFaceRetouchPanelItems(currentLevel);
      case _PanelMode.saveShare:
        return _liveCapture.canOpenSaveSharePanel
            ? buildVideoClipPanelItems()
            : buildPhotoEditPanelItems(currentLevel);
      case _PanelMode.none:
        return const <String>[];
    }
  }

  Future<void> _handleMenuPress(EditorState state) async {
    if (_liveCapture.isActive) {
      await _leaveLiveCaptureMode(this);
      return;
    }

    if (state.hasSession || state.isBusy) {
      _returnToHome();
      return;
    }

    if (_panelMode != _PanelMode.none) {
      _closePanel();
    }
  }

  Future<void> _handleModeTogglePress(EditorState state) async {
    if (_isShellBusy(state) && !_liveCapture.isActive) {
      return;
    }
    if (_liveCapture.isActive) {
      final bool didToggle = await _toggleLiveCaptureLens(this);
      if (didToggle) {
        _showSystemMessage(
          this,
          AppLocalizations.current.switchedLensMessage(
            isFront: _liveCapture.isFrontLens,
          ),
        );
      }
      return;
    }

    await _handleMenuPress(state);
  }

  Future<void> _handleStampPress(
    EditorController controller,
    EditorState state,
  ) async {
    if (_isShellBusy(state)) {
      return;
    }
    if (_liveCapture.isActive) {
      await _handleLiveCapturePrimaryAction(this, controller);
      return;
    }
    if (!state.hasSession) {
      return;
    }
    _openPanel(_PanelMode.sticker);
  }

  void _handleSaveSharePress(EditorState state) {
    if (_isShellBusy(state)) {
      return;
    }
    if (_liveCapture.isActive) {
      if (_liveCapture.canOpenSaveSharePanel) {
        _openPanel(_PanelMode.saveShare);
      }
      return;
    }
    if (!state.hasSession) {
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
    if (_isShellBusy(state)) {
      return;
    }
    if (_panelMode != _PanelMode.none) {
      if (up || left) {
        _movePanelCursor(-1);
      } else if (down || right) {
        _movePanelCursor(1);
      }
      return;
    }

    if (_liveCapture.isActive) {
      return;
    }

    if (!state.hasSession) {
      final List<HomeAction> homeActions = buildEditorHomeActions();
      final int delta = (up || left)
          ? -1
          : (down || right)
          ? 1
          : 0;
      if (delta == 0) {
        return;
      }
      setState(() {
        _sourceSelectionIndex =
            (_sourceSelectionIndex + delta + homeActions.length) %
            homeActions.length;
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
    final EditorState state = ref.read(editorControllerProvider);
    if (_isShellBusy(state)) {
      return;
    }
    if (_panelMode == _PanelMode.none && _liveCapture.isActive) {
      await _handleLiveCapturePrimaryAction(this, controller);
      return;
    }

    if (_panelMode == _PanelMode.none) {
      if (!state.hasSession) {
        switch (buildEditorHomeActions()[_sourceSelectionIndex].kind) {
          case HomeActionKind.photoCapture:
            await _enterLiveCaptureMode(this, LiveCaptureMode.photo);
            return;
          case HomeActionKind.videoCapture:
            await _enterLiveCaptureMode(this, LiveCaptureMode.video);
            return;
          case HomeActionKind.galleryEdit:
            await controller.startSession(ImageInputType.gallery);
            return;
        }
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

    if (_liveCapture.canOpenSaveSharePanel) {
      await _handleVideoPanelSelection();
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

  Future<void> _handleVideoPanelSelection() async {
    final int selected = _panelIndex;
    _closePanel();

    if (selected == 0) {
      await _saveRecordedVideo(this);
    } else if (selected == 1) {
      await _shareRecordedVideo(this);
    } else {
      await _deleteRecordedVideo(this);
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
    if (!mounted) {
      return;
    }
    setState(update);
  }

  bool _isShellBusy(EditorState state) {
    return state.isBusy ||
        _liveCapture.isInitializing ||
        _liveCapture.isCapturingStill ||
        _isLiveCaptureActionBusy;
  }

  void _returnToHome() {
    // ホーム復帰時は画面内状態もメッセージも初期位置へ戻す。
    ref.read(editorControllerProvider.notifier).returnToHome();
    _systemMessageTimer?.cancel();
    _applyUiUpdate(() {
      _panelMode = _PanelMode.none;
      _panelIndex = 0;
      _sourceSelectionIndex = 0;
      _systemMessage = null;
    });
  }
}
