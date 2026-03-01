// Orchestrates image import, retro filtering, keypad sticker editing, and export actions.
/*
Dependency Memo
- Depends on: domain entities/repositories and app_exception.dart for flow control.
- Requires methods: pickFromCamera(), pickFromGallery(), applyGarakeFilter(), compose(), saveJpeg(), shareImage().
- Provides methods: startSession(), startSessionFromBytes(), addSticker(), deleteSelectedSticker(), onArrowUp(), onArrowDown(), onArrowLeft(), onArrowRight(), onOkPressed(), updateCanvasTransform(), saveCurrentImage(), shareCurrentImage().
*/
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../domain/entities/canvas_transform.dart';
import '../domain/entities/editor_session.dart';
import '../domain/entities/filter_config.dart';
import '../domain/entities/sticker_item.dart';
import '../domain/enums/image_input_type.dart';
import '../domain/repositories/export_repository.dart';
import '../domain/repositories/filter_engine.dart';
import '../domain/repositories/image_source_repository.dart';
import '../domain/repositories/sticker_composer.dart';
import 'editor_state.dart';

class EditorController extends StateNotifier<EditorState> {
  EditorController({
    required ImageSourceRepository imageSourceRepository,
    required FilterEngine filterEngine,
    required StickerComposer stickerComposer,
    required ExportRepository exportRepository,
    required FilterConfig filterConfig,
    DateTime Function()? now,
  }) : _imageSourceRepository = imageSourceRepository,
       _filterEngine = filterEngine,
       _stickerComposer = stickerComposer,
       _exportRepository = exportRepository,
       _filterConfig = filterConfig,
       _now = now ?? DateTime.now,
       super(const EditorState());

  final ImageSourceRepository _imageSourceRepository;
  final FilterEngine _filterEngine;
  final StickerComposer _stickerComposer;
  final ExportRepository _exportRepository;
  final FilterConfig _filterConfig;
  final DateTime Function() _now;
  int _stickerCounter = 0;

  static const List<String> availableStickerAssets = <String>[
    'assets/stickers/heart_red.png',
    'assets/stickers/heart_pink.png',
    'assets/stickers/star_yellow.png',
    'assets/stickers/star_orange.png',
    'assets/stickers/sparkle_gold.png',
    'assets/stickers/sparkle_pink.png',
  ];

  Future<void> startSession(ImageInputType source) async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: EditorStatus.picking,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      final Uint8List inputBytes = switch (source) {
        ImageInputType.camera => await _imageSourceRepository.pickFromCamera(),
        ImageInputType.gallery =>
          await _imageSourceRepository.pickFromGallery(),
      };
      await _startSessionFromInputBytes(inputBytes, pickedFromSource: true);
    } catch (error) {
      if (error is AppException) {
        state = state.copyWith(
          status: state.hasSession ? EditorStatus.ready : EditorStatus.idle,
          errorMessage: error.userMessage,
          clearInfoMessage: true,
        );
      } else {
        state = state.copyWith(
          status: state.hasSession ? EditorStatus.ready : EditorStatus.error,
          errorMessage: '画像の読み込みに失敗しました。',
          clearInfoMessage: true,
        );
      }
    }
  }

  Future<void> startSessionFromBytes(Uint8List inputBytes) async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: EditorStatus.processing,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      await _startSessionFromInputBytes(inputBytes, pickedFromSource: false);
    } catch (error) {
      if (error is AppException) {
        state = state.copyWith(
          status: state.hasSession ? EditorStatus.ready : EditorStatus.idle,
          errorMessage: error.userMessage,
          clearInfoMessage: true,
        );
      } else {
        state = state.copyWith(
          status: state.hasSession ? EditorStatus.ready : EditorStatus.error,
          errorMessage: '画像の読み込みに失敗しました。',
          clearInfoMessage: true,
        );
      }
    }
  }

  Future<void> _startSessionFromInputBytes(
    Uint8List inputBytes, {
    required bool pickedFromSource,
  }) async {
    if (pickedFromSource) {
      state = state.copyWith(status: EditorStatus.processing);
    }

    final img.Image? decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      throw const AppException('読み込めない画像形式です。');
    }

    final DateTime stampDate = _now();
    final Uint8List filteredBytes = await _filterEngine.applyGarakeFilter(
      inputBytes,
      _filterConfig,
      stampDate,
    );

    state = state.copyWith(
      status: EditorStatus.ready,
      keypadMode: KeypadMode.move,
      session: EditorSession(
        originalBytes: inputBytes,
        filteredBytes: filteredBytes,
        originalImageSize: Size(
          decoded.width.toDouble(),
          decoded.height.toDouble(),
        ),
        stickers: const <StickerItem>[],
        stampDate: stampDate,
        filterConfig: _filterConfig,
        canvasTransform: CanvasTransform.identity,
      ),
      infoMessage: '画像を読み込みました。',
      clearErrorMessage: true,
    );
  }

  void addSticker(String assetPath) {
    final EditorSession? session = state.session;
    if (session == null) {
      state = state.copyWith(errorMessage: '先に写真を選択してください。');
      return;
    }

    final Random random = Random(
      _stickerCounter + session.stickers.length + 13,
    );
    final StickerItem newItem = StickerItem(
      id: 'sticker_${_stickerCounter++}',
      assetPath: assetPath,
      normalizedOffset: Offset(
        0.25 + random.nextDouble() * 0.5,
        0.22 + random.nextDouble() * 0.56,
      ),
      scale: 1,
      selected: true,
    );

    final List<StickerItem> next =
        session.stickers
            .map((StickerItem item) => item.copyWith(selected: false))
            .toList(growable: true)
          ..add(newItem);

    state = state.copyWith(
      keypadMode: KeypadMode.move,
      session: session.copyWith(stickers: next),
      infoMessage: 'スタンプを追加しました。',
      clearErrorMessage: true,
    );
  }

  void deleteSelectedSticker() {
    final EditorSession? session = state.session;
    if (session == null) {
      return;
    }
    final StickerItem? selected = session.selectedSticker;
    if (selected == null) {
      state = state.copyWith(errorMessage: '削除するスタンプを選択してください。');
      return;
    }

    final List<StickerItem> next = session.stickers
        .where((StickerItem item) => item.id != selected.id)
        .toList(growable: false);
    state = state.copyWith(
      session: session.copyWith(stickers: next),
      infoMessage: 'スタンプを削除しました。',
      clearErrorMessage: true,
    );
  }

  void onArrowUp() {
    _handleArrow(vertical: -1);
  }

  void onArrowDown() {
    _handleArrow(vertical: 1);
  }

  void onArrowLeft() {
    _handleArrow(horizontal: -1);
  }

  void onArrowRight() {
    _handleArrow(horizontal: 1);
  }

  void onOkPressed() {
    final EditorSession? session = state.session;
    if (session == null) {
      return;
    }

    if (session.stickers.isEmpty) {
      state = state.copyWith(errorMessage: '先にスタンプを追加してください。');
      return;
    }

    final StickerItem? selected = session.selectedSticker;
    if (selected == null) {
      _selectStickerByOffset(0);
      state = state.copyWith(infoMessage: 'スタンプを選択しました。');
      return;
    }

    final KeypadMode nextMode = state.keypadMode == KeypadMode.move
        ? KeypadMode.scale
        : KeypadMode.move;
    state = state.copyWith(
      keypadMode: nextMode,
      infoMessage: nextMode == KeypadMode.move ? '移動モード' : '拡大縮小モード',
    );
  }

  void updateCanvasTransform(CanvasTransform transform) {
    final EditorSession? session = state.session;
    if (session == null) {
      return;
    }
    if (session.canvasTransform.closeTo(transform)) {
      return;
    }

    state = state.copyWith(
      session: session.copyWith(canvasTransform: transform),
    );
  }

  Future<void> saveCurrentImage() async {
    final EditorSession? session = state.session;
    if (session == null || state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: EditorStatus.saving,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      final Uint8List output = await _buildOutputBytes(session);
      final result = await _exportRepository.saveJpeg(output);
      state = state.copyWith(
        status: EditorStatus.ready,
        infoMessage: '保存しました: ${result.filePath}',
      );
    } catch (error) {
      if (error is AppException) {
        state = state.copyWith(
          status: EditorStatus.ready,
          errorMessage: error.userMessage,
        );
        return;
      }
      state = state.copyWith(
        status: EditorStatus.ready,
        errorMessage: '保存に失敗しました。',
      );
    }
  }

  Future<void> shareCurrentImage() async {
    final EditorSession? session = state.session;
    if (session == null || state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: EditorStatus.sharing,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      final Uint8List output = await _buildOutputBytes(session);
      await _exportRepository.shareImage(output, text: 'ガラケーカメラで加工しました');
      state = state.copyWith(
        status: EditorStatus.ready,
        infoMessage: '共有シートを開きました。',
      );
    } catch (error) {
      if (error is AppException) {
        state = state.copyWith(
          status: EditorStatus.ready,
          errorMessage: error.userMessage,
        );
        return;
      }
      state = state.copyWith(
        status: EditorStatus.ready,
        errorMessage: '共有に失敗しました。',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearErrorMessage: true, clearInfoMessage: true);
  }

  void _handleArrow({int horizontal = 0, int vertical = 0}) {
    final EditorSession? session = state.session;
    if (session == null || session.stickers.isEmpty) {
      return;
    }

    final StickerItem? selected = session.selectedSticker;
    if (selected == null) {
      _selectStickerByOffset(0);
      return;
    }

    if (state.keypadMode == KeypadMode.move) {
      final Offset nextOffset = Offset(
        (selected.normalizedOffset.dx + horizontal * 0.018).clamp(0.0, 1.0),
        (selected.normalizedOffset.dy + vertical * 0.018).clamp(0.0, 1.0),
      );
      _updateSticker(selected.id, offset: nextOffset);
      return;
    }

    if (vertical != 0) {
      final double nextScale = (selected.scale + vertical * -0.08).clamp(
        0.4,
        3.2,
      );
      _updateSticker(selected.id, scale: nextScale);
      return;
    }

    if (horizontal != 0) {
      _selectStickerByOffset(horizontal);
    }
  }

  void _selectStickerByOffset(int delta) {
    final EditorSession? session = state.session;
    if (session == null || session.stickers.isEmpty) {
      return;
    }

    int index = session.stickers.indexWhere(
      (StickerItem item) => item.selected,
    );
    if (index < 0) {
      index = 0;
    } else {
      index = (index + delta) % session.stickers.length;
      if (index < 0) {
        index += session.stickers.length;
      }
    }

    final List<StickerItem> next = List<StickerItem>.generate(
      session.stickers.length,
      (int i) => session.stickers[i].copyWith(selected: i == index),
      growable: false,
    );

    state = state.copyWith(session: session.copyWith(stickers: next));
  }

  void _updateSticker(String stickerId, {Offset? offset, double? scale}) {
    final EditorSession? session = state.session;
    if (session == null) {
      return;
    }

    final List<StickerItem> next = session.stickers
        .map((StickerItem item) {
          if (item.id != stickerId) {
            return item;
          }
          return item.copyWith(
            normalizedOffset: offset ?? item.normalizedOffset,
            scale: scale ?? item.scale,
          );
        })
        .toList(growable: false);

    state = state.copyWith(session: session.copyWith(stickers: next));
  }

  Future<Uint8List> _buildOutputBytes(EditorSession session) {
    return _stickerComposer.compose(
      session.filteredBytes,
      session.stickers,
      session.stampDate,
    );
  }
}
