// Hosts the full Garake UI with home menu and editor/camera in a single screen.
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
import '../../domain/entities/sticker_item.dart';
import '../../domain/enums/image_input_type.dart';
import '../widgets/editor_canvas.dart';
import '../widgets/garake_menu.dart';
import '../widgets/garake_shell.dart';
import '../widgets/live_camera_preview.dart';

enum _PanelMode { none, source, sticker, saveShare }

/// 画面全体のモード。ホームメニュー ↔ エディター/カメラ をインプレースで切り替える。
enum _ScreenMode { home, editor }

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  _ScreenMode _screenMode = _ScreenMode.home;
  _PanelMode _panelMode = _PanelMode.none;
  int _panelIndex = 0;
  bool _isLiveCameraMode = false;
  bool _isInitializingCamera = false;
  bool _isCapturing = false;
  String? _cameraErrorMessage;
  String? _systemMessage;
  Timer? _systemMessageTimer;
  CameraController? _liveCameraController;

  // ホーム画面用の状態。
  int _homeSelectedIndex = 0;
  static const List<_HomeAction> _homeActions = <_HomeAction>[
    _HomeAction(
      title: '写真を撮る',
      subtitle: 'カメラで撮影して加工',
      source: ImageInputType.camera,
    ),
    _HomeAction(
      title: '写真を編集する',
      subtitle: 'アルバムから読み込む',
      source: ImageInputType.gallery,
    ),
  ];

  static const List<String> _saveShareItems = <String>['保存する', 'シェアする', '削除'];

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
    if (_screenMode == _ScreenMode.home) {
      return _buildHomeShell();
    }
    return _buildEditorShell();
  }

  // ---------------------------------------------------------------------------
  // ホーム画面
  // ---------------------------------------------------------------------------

  Widget _buildHomeShell() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1E28),
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: GarakeShell(
          isBusy: false,
          photoLoaded: true,
          modeLabel: 'HOME',
          selectionLabel: '${_homeSelectedIndex + 1}/${_homeActions.length}',
          menuKeyLabel: _homeActions[0].title,
          stampKeyLabel: '項目切替',
          saveShareKeyLabel: _homeActions[1].title,
          onMenuPressed: () => _openHomeAction(_homeActions[0]),
          onStampPressed: _selectNextHomeAction,
          onSaveSharePressed: () => _openHomeAction(_homeActions[1]),
          onUpPressed: () => _moveHomeSelection(-1),
          onDownPressed: () => _moveHomeSelection(1),
          onLeftPressed: () => _moveHomeSelection(-1),
          onRightPressed: () => _moveHomeSelection(1),
          onOkPressed: () => _openHomeAction(_homeActions[_homeSelectedIndex]),
          preview: _HomeDisplay(
            actions: _homeActions,
            selectedIndex: _homeSelectedIndex,
          ),
        ),
      ),
    );
  }

  void _moveHomeSelection(int delta) {
    setState(() {
      _homeSelectedIndex = (_homeSelectedIndex + delta) % _homeActions.length;
      if (_homeSelectedIndex < 0) {
        _homeSelectedIndex += _homeActions.length;
      }
    });
  }

  void _selectNextHomeAction() {
    _moveHomeSelection(1);
  }

  Future<void> _openHomeAction(_HomeAction action) async {
    setState(() {
      _screenMode = _ScreenMode.editor;
    });
    if (action.source == ImageInputType.camera) {
      await _enterLiveCameraMode();
    } else {
      await ref
          .read(editorControllerProvider.notifier)
          .startSession(action.source);
    }
  }

  // ---------------------------------------------------------------------------
  // エディター / カメラ画面
  // ---------------------------------------------------------------------------

  Widget _buildEditorShell() {
    ref.listen<EditorState>(editorControllerProvider, _handleStateMessages);

    final EditorState state = ref.watch(editorControllerProvider);
    final EditorController controller = ref.read(
      editorControllerProvider.notifier,
    );
    final List<StickerItem> stickers =
        state.session?.stickers ?? const <StickerItem>[];

    final bool showLiveCamera = _isLiveCameraMode;
    final int selectedIndex = stickers.indexWhere(
      (StickerItem item) => item.selected,
    );
    final String selectionLabel = showLiveCamera
        ? (_cameraErrorMessage == null ? 'SHOT' : 'ERR')
        : selectedIndex >= 0
        ? 'ST:${selectedIndex + 1}/${stickers.length}'
        : stickers.isEmpty
        ? 'ST:0/0'
        : 'ST:None/${stickers.length}';

    final String modeLabel = showLiveCamera
        ? 'CAM'
        : (state.keypadMode == KeypadMode.move ? 'MOVE' : 'SCALE');

    // メニューが開いているときはガラケー画面内にメニューを表示。
    final Widget? menuWidget = _panelMode != _PanelMode.none
        ? GarakeMenu(
            title: _panelTitle,
            items: _panelItems,
            selectedIndex: _panelIndex,
            onUpPressed: () => _movePanelCursor(-1),
            onDownPressed: () => _movePanelCursor(1),
            onOkPressed: () => _handleOk(controller),
          )
        : null;

    final bool shellBusy =
        state.isBusy || _isInitializingCamera || _isCapturing;

    // 全画面カワイイ風ガラケーを表示。
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A14),
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: GarakeShell(
          isBusy: shellBusy,
          photoLoaded: showLiveCamera || state.hasSession,
          modeLabel: modeLabel,
          selectionLabel: selectionLabel,
          menuWidget: menuWidget,
          menuKeyLabel: showLiveCamera ? '入力切替' : 'ホーム',
          stampKeyLabel: showLiveCamera ? '撮影' : 'スタンプ',
          saveShareKeyLabel: showLiveCamera ? '---' : '保存/シェア',
          systemMessage: _systemMessage,
          onMenuPressed: () => _openPanel(_PanelMode.source),
          onStampPressed: () => _handleStampPress(controller),
          onSaveSharePressed: () => _handleSaveSharePress(),
          onUpPressed: () => _handleArrow(controller, up: true),
          onDownPressed: () => _handleArrow(controller, down: true),
          onLeftPressed: () => _handleArrow(controller, left: true),
          onRightPressed: () => _handleArrow(controller, right: true),
          onOkPressed: () => _handleOk(controller),
          preview: showLiveCamera
              ? LiveCameraPreview(
                  controller: _liveCameraController,
                  isInitializing: _isInitializingCamera,
                  errorMessage: _cameraErrorMessage,
                )
              : EditorCanvas(
                  filteredBytes: state.session?.filteredBytes,
                  imageSize: state.session?.originalImageSize,
                  stickers: stickers,
                  onCanvasTransformChanged: controller.updateCanvasTransform,
                  onCameraPressed: () => _enterLiveCameraMode(),
                  onEditPhotoPressed: () =>
                      controller.startSession(ImageInputType.gallery),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // エディター内部のパネル / キー操作
  // ---------------------------------------------------------------------------

  String get _panelTitle {
    switch (_panelMode) {
      case _PanelMode.source:
        return '画像入力';
      case _PanelMode.sticker:
        return 'スタンプ追加';
      case _PanelMode.saveShare:
        return '保存/シェア';
      case _PanelMode.none:
        return '';
    }
  }

  List<String> get _panelItems {
    switch (_panelMode) {
      case _PanelMode.source:
        return ImageInputType.values
            .map((ImageInputType e) => e.label)
            .toList();
      case _PanelMode.sticker:
        return EditorController.availableStickerAssets
            .asMap()
            .entries
            .map((MapEntry<int, String> e) => 'スタンプ ${e.key + 1}')
            .toList();
      case _PanelMode.saveShare:
        return _saveShareItems;
      case _PanelMode.none:
        return const <String>[];
    }
  }

  void _openPanel(_PanelMode mode) {
    setState(() {
      _panelMode = mode;
      _panelIndex = 0;
    });
  }

  void _closePanel() {
    setState(() {
      _panelMode = _PanelMode.none;
      _panelIndex = 0;
    });
  }

  Future<void> _handleStampPress(EditorController controller) async {
    if (_isLiveCameraMode) {
      await _captureFromLiveCamera(controller);
      return;
    }
    _openPanel(_PanelMode.sticker);
  }

  void _handleSaveSharePress() {
    if (_isLiveCameraMode) {
      return;
    }
    _openPanel(_PanelMode.saveShare);
  }

  // D-padの矢印操作。メニュー中はカーソル移動、それ以外はスタンプ操作。
  void _handleArrow(
    EditorController controller, {
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

  Future<void> _handleOk(EditorController controller) async {
    // メニューが閉じていてライブカメラ中なら撮影する。
    if (_panelMode == _PanelMode.none && _isLiveCameraMode) {
      await _captureFromLiveCamera(controller);
      return;
    }

    // メニューが閉じているときは通常のOK操作。
    if (_panelMode == _PanelMode.none) {
      controller.onOkPressed();
      return;
    }

    switch (_panelMode) {
      case _PanelMode.source:
        final ImageInputType selected = ImageInputType.values[_panelIndex];
        _closePanel();
        if (selected == ImageInputType.camera) {
          await _enterLiveCameraMode();
        } else {
          await _leaveLiveCameraMode();
          await controller.startSession(selected);
        }
        break;
      case _PanelMode.sticker:
        final String asset =
            EditorController.availableStickerAssets[_panelIndex];
        _closePanel();
        controller.addSticker(asset);
        break;
      case _PanelMode.saveShare:
        final int selected = _panelIndex;
        _closePanel();
        if (selected == 0) {
          await controller.saveCurrentImage();
        } else if (selected == 1) {
          await controller.shareCurrentImage();
        } else {
          controller.deleteSelectedSticker();
        }
        break;
      case _PanelMode.none:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // ライブカメラ制御
  // ---------------------------------------------------------------------------

  Future<void> _enterLiveCameraMode() async {
    if (_isInitializingCamera) {
      return;
    }

    await _disposeLiveCameraController();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLiveCameraMode = true;
      _isInitializingCamera = true;
      _isCapturing = false;
      _cameraErrorMessage = null;
    });

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('カメラが見つかりません');
      }

      final CameraDescription selectedCamera = cameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final CameraController controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _liveCameraController = controller;
        _isInitializingCamera = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializingCamera = false;
        _cameraErrorMessage = 'カメラを起動できませんでした。権限と端末設定を確認してください。';
      });
    }
  }

  Future<void> _leaveLiveCameraMode() async {
    await _disposeLiveCameraController();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLiveCameraMode = false;
      _isInitializingCamera = false;
      _isCapturing = false;
      _cameraErrorMessage = null;
    });
  }

  Future<void> _captureFromLiveCamera(EditorController controller) async {
    if (!_isLiveCameraMode || _isInitializingCamera || _isCapturing) {
      return;
    }

    final CameraController? cameraController = _liveCameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      setState(() {
        _cameraErrorMessage = 'カメラの準備ができていません。';
      });
      return;
    }

    setState(() {
      _isCapturing = true;
      _cameraErrorMessage = null;
    });

    try {
      final XFile imageFile = await cameraController.takePicture();
      final bytes = await imageFile.readAsBytes();

      await _leaveLiveCameraMode();
      if (!mounted) {
        return;
      }

      await controller.startSessionFromBytes(bytes);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCapturing = false;
        _cameraErrorMessage = '撮影に失敗しました。もう一度お試しください。';
      });
    }
  }

  Future<void> _disposeLiveCameraController() async {
    final CameraController? controller = _liveCameraController;
    _liveCameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  // エラー・情報メッセージをガラケー画面内に表示。
  void _handleStateMessages(EditorState? previous, EditorState next) {
    final String? error = next.errorMessage;
    final String? info = next.infoMessage;

    if (error != null && error != previous?.errorMessage) {
      _showSystemMessage(error);
      ref.read(editorControllerProvider.notifier).clearMessages();
      return;
    }

    if (info != null && info != previous?.infoMessage) {
      _showSystemMessage(info);
      ref.read(editorControllerProvider.notifier).clearMessages();
    }
  }

  // ガラケー画面内に一時メッセージを表示して没入感を保つ。
  void _showSystemMessage(String message) {
    _systemMessageTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _systemMessage = message;
    });
    _systemMessageTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _systemMessage = null;
      });
    });
  }
}

// ---------------------------------------------------------------------------
// ホーム画面内の表示ウィジェット群
// ---------------------------------------------------------------------------

class _HomeDisplay extends StatelessWidget {
  const _HomeDisplay({required this.actions, required this.selectedIndex});

  final List<_HomeAction> actions;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // 液晶の奥行きを出すため、暗いグラデーション背景を敷く。
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF252B34), Color(0xFF0F1218)],
            ),
          ),
        ),
        // ガラケー風のデコレーションを重ねて元画像の雰囲気に寄せる。
        const Positioned(
          top: 18,
          left: 18,
          child: _PixelHeart(color: Color(0xFFE74D5C)),
        ),
        const Positioned(
          top: 26,
          right: 20,
          child: _PixelHeart(color: Color(0xFFF399C4)),
        ),
        const Positioned(bottom: 28, left: 20, child: _PixelStar()),
        const Positioned(bottom: 34, right: 24, child: _PixelSparkle()),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(actions.length, (int index) {
                    final bool selected = index == selectedIndex;
                    final _HomeAction action = actions[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFDEE1E9)
                            : const Color(0x0FFFFFFF),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFEDEFF5)
                              : const Color(0xFF5D6573),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            selected ? '▶' : '・',
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF15181D)
                                  : const Color(0xFFBBC2CE),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  action.title,
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFF15181D)
                                        : const Color(0xFFE3E6ED),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  action.subtitle,
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFF414754)
                                        : const Color(0xFF8E97A8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '↑↓で選択 / OKで決定',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB0B6C4),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PixelHeart extends StatelessWidget {
  const _PixelHeart({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '❤',
      style: TextStyle(
        color: color,
        fontSize: 22,
        shadows: const <Shadow>[
          Shadow(color: Colors.black87, offset: Offset(1, 1)),
        ],
      ),
    );
  }
}

class _PixelStar extends StatelessWidget {
  const _PixelStar();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '★',
      style: TextStyle(
        color: Color(0xFFF4E64F),
        fontSize: 24,
        shadows: <Shadow>[Shadow(color: Colors.black87, offset: Offset(1, 1))],
      ),
    );
  }
}

class _PixelSparkle extends StatelessWidget {
  const _PixelSparkle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '✦',
      style: TextStyle(
        color: Color(0xFFEED96B),
        fontSize: 26,
        shadows: <Shadow>[Shadow(color: Colors.black87, offset: Offset(1, 1))],
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.source,
  });

  final String title;
  final String subtitle;
  final ImageInputType source;
}
