// Orchestrates image import, face-retouch rerendering, keypad sticker editing, and export actions.
/*
Dependency Memo
- Depends on: domain entities/repositories, editor_image_pipeline.dart, and app_exception.dart for flow control.
- Requires methods: pickFromCamera(), pickFromGallery(), loadSessionData(), renderFilteredPreview(), compose(), saveJpeg(), shareImage().
- Provides methods: startSession(), startSessionFromBytes(), returnToHome(), updateFaceRetouchLevel(), addSticker(), deleteSelectedSticker(), onArrowUp(), onArrowDown(), onArrowLeft(), onArrowRight(), onOkPressed(), updateCanvasTransform(), saveCurrentImage(), shareCurrentImage().
*/
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/entities/canvas_transform.dart';
import '../domain/entities/editor_session.dart';
import '../domain/entities/face_retouch_level.dart';
import '../domain/entities/filter_config.dart';
import '../domain/entities/sticker_item.dart';
import '../domain/enums/image_input_type.dart';
import '../domain/repositories/export_repository.dart';
import '../domain/repositories/image_source_repository.dart';
import '../domain/repositories/sticker_composer.dart';
import 'editor_image_pipeline.dart';
import 'editor_state.dart';

class EditorController extends StateNotifier<EditorState> {
  EditorController({
    required ImageSourceRepository imageSourceRepository,
    required EditorImagePipeline imagePipeline,
    required StickerComposer stickerComposer,
    required ExportRepository exportRepository,
    required FilterConfig filterConfig,
    DateTime Function()? now,
  }) : _imageSourceRepository = imageSourceRepository,
       _imagePipeline = imagePipeline,
       _stickerComposer = stickerComposer,
       _exportRepository = exportRepository,
       _filterConfig = filterConfig,
       _now = now ?? DateTime.now,
       super(const EditorState());

  final ImageSourceRepository _imageSourceRepository;
  final EditorImagePipeline _imagePipeline;
  final StickerComposer _stickerComposer;
  final ExportRepository _exportRepository;
  final FilterConfig _filterConfig;
  final DateTime Function() _now;
  int _stickerCounter = 0;
  int _operationVersion = 0;

  static const List<String> availableStickerAssets = <String>[
    'assets/stickers/heart_red.png',
    'assets/stickers/heart_pink.png',
    'assets/stickers/star_yellow.png',
    'assets/stickers/star_orange.png',
    'assets/stickers/sparkle_gold.png',
    'assets/stickers/sparkle_pink.png',
  ];

  Future<void> startSession(ImageInputType source) async {
    final AppLocalizations l10n = AppLocalizations.current;
    if (state.isBusy) {
      return;
    }
    final int operationVersion = _beginOperation();
    state = state.copyWith(
      status: EditorStatus.picking,
      busyMessage: source == ImageInputType.gallery
          ? l10n.busyOpeningAlbum
          : l10n.busyOpeningCamera,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      final Uint8List inputBytes = switch (source) {
        ImageInputType.camera => await _imageSourceRepository.pickFromCamera(),
        ImageInputType.gallery =>
          await _imageSourceRepository.pickFromGallery(),
      };
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      await _startSessionFromInputBytes(
        inputBytes,
        pickedFromSource: true,
        operationVersion: operationVersion,
      );
    } catch (error) {
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      if (error is AppException) {
        state = state.copyWith(
          status: state.hasSession ? EditorStatus.ready : EditorStatus.idle,
          clearBusyMessage: true,
          errorMessage: error.userMessage,
          clearInfoMessage: true,
        );
      } else {
        state = state.copyWith(
          status: state.hasSession ? EditorStatus.ready : EditorStatus.error,
          clearBusyMessage: true,
          errorMessage: l10n.imageLoadFailedMessage,
          clearInfoMessage: true,
        );
      }
    }
  }

  Future<void> startSessionFromBytes(
    Uint8List inputBytes, {
    String? busyMessage,
    bool showLoadedMessage = true,
  }) async {
    final AppLocalizations l10n = AppLocalizations.current;
    if (state.isBusy) {
      return;
    }
    final int operationVersion = _beginOperation();
    state = state.copyWith(
      status: EditorStatus.processing,
      busyMessage: busyMessage ?? l10n.busyProcessingPhoto,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      await _startSessionFromInputBytes(
        inputBytes,
        pickedFromSource: false,
        operationVersion: operationVersion,
        showLoadedMessage: showLoadedMessage,
      );
    } catch (error) {
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      if (error is AppException) {
        state = state.copyWith(
          status: state.hasSession ? EditorStatus.ready : EditorStatus.idle,
          clearBusyMessage: true,
          errorMessage: error.userMessage,
          clearInfoMessage: true,
        );
      } else {
        state = state.copyWith(
          status: state.hasSession ? EditorStatus.ready : EditorStatus.error,
          clearBusyMessage: true,
          errorMessage: l10n.imageLoadFailedMessage,
          clearInfoMessage: true,
        );
      }
    }
  }

  Future<void> _startSessionFromInputBytes(
    Uint8List inputBytes, {
    required bool pickedFromSource,
    required int operationVersion,
    bool showLoadedMessage = true,
  }) async {
    final AppLocalizations l10n = AppLocalizations.current;
    if (pickedFromSource) {
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      state = state.copyWith(
        status: EditorStatus.processing,
        busyMessage: l10n.busyProcessingAlbumPhoto,
      );
    }

    final DateTime stampDate = _now();
    final EditorImageLoadResult loadResult = await _imagePipeline
        .loadSessionData(inputBytes, stampDate);
    if (!_isOperationActive(operationVersion)) {
      return;
    }

    state = state.copyWith(
      status: EditorStatus.ready,
      keypadMode: KeypadMode.move,
      session: EditorSession(
        originalBytes: inputBytes,
        filteredBytes: loadResult.filteredBytes,
        originalImageSize: loadResult.originalImageSize,
        stickers: const <StickerItem>[],
        stampDate: stampDate,
        detectedFaces: loadResult.detectedFaces,
        faceRetouchLevel: FaceRetouchLevel.off,
        filterConfig: _filterConfig,
        canvasTransform: CanvasTransform.identity,
      ),
      clearBusyMessage: true,
      infoMessage: showLoadedMessage ? l10n.imageLoadedMessage : null,
      clearErrorMessage: true,
      clearInfoMessage: !showLoadedMessage,
    );
  }

  void returnToHome() {
    // ホーム復帰時は進行中の非同期完了を無視してホーム表示を維持する。
    _invalidatePendingOperations();
    _stickerCounter = 0;
    state = const EditorState();
  }

  void addSticker(String assetPath) {
    final AppLocalizations l10n = AppLocalizations.current;
    final EditorSession? session = state.session;
    if (session == null) {
      state = state.copyWith(errorMessage: l10n.selectPhotoFirstMessage);
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
      infoMessage: l10n.stickerAddedMessage,
      clearErrorMessage: true,
    );
  }

  void deleteSelectedSticker() {
    final AppLocalizations l10n = AppLocalizations.current;
    final EditorSession? session = state.session;
    if (session == null) {
      return;
    }
    final StickerItem? selected = session.selectedSticker;
    if (selected == null) {
      state = state.copyWith(errorMessage: l10n.selectStickerToDeleteMessage);
      return;
    }

    final List<StickerItem> next = session.stickers
        .where((StickerItem item) => item.id != selected.id)
        .toList(growable: false);
    state = state.copyWith(
      session: session.copyWith(stickers: next),
      infoMessage: l10n.stickerDeletedMessage,
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
    final AppLocalizations l10n = AppLocalizations.current;
    final EditorSession? session = state.session;
    if (session == null) {
      return;
    }

    if (session.stickers.isEmpty) {
      state = state.copyWith(errorMessage: l10n.addStickerFirstMessage);
      return;
    }

    final StickerItem? selected = session.selectedSticker;
    if (selected == null) {
      _selectStickerByOffset(0);
      state = state.copyWith(infoMessage: l10n.stickerSelectedMessage);
      return;
    }

    final KeypadMode nextMode = state.keypadMode == KeypadMode.move
        ? KeypadMode.scale
        : KeypadMode.move;
    state = state.copyWith(
      keypadMode: nextMode,
      infoMessage: nextMode == KeypadMode.move
          ? l10n.moveModeMessage
          : l10n.scaleModeMessage,
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

  Future<void> updateFaceRetouchLevel(
    FaceRetouchLevel level, {
    bool announce = true,
  }) async {
    final AppLocalizations l10n = AppLocalizations.current;
    final EditorSession? session = state.session;
    if (session == null || state.isBusy) {
      return;
    }
    final String levelLabel = l10n.faceRetouchLabel(enabled: level.isEnabled);
    if (session.faceRetouchLevel == level) {
      state = state.copyWith(
        infoMessage: l10n.faceRetouchUnchangedMessage(levelLabel),
      );
      return;
    }
    if (level.isEnabled && !session.canRetouchFace) {
      state = state.copyWith(errorMessage: l10n.faceRetouchNoFaceMessage);
      return;
    }
    final int operationVersion = _beginOperation();

    state = state.copyWith(
      status: EditorStatus.processing,
      busyMessage: l10n.busyPreparingFaceRetouch,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      final Uint8List filteredBytes = await _imagePipeline
          .renderFilteredPreview(
            inputBytes: session.originalBytes,
            stampDate: session.stampDate,
            detectedFaces: session.detectedFaces,
            faceRetouchLevel: level,
          );
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      state = state.copyWith(
        status: EditorStatus.ready,
        session: session.copyWith(
          filteredBytes: filteredBytes,
          faceRetouchLevel: level,
        ),
        clearBusyMessage: true,
        infoMessage: announce
            ? l10n.faceRetouchUpdatedMessage(levelLabel)
            : null,
        clearInfoMessage: !announce,
      );
    } catch (_) {
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      state = state.copyWith(
        status: EditorStatus.ready,
        clearBusyMessage: true,
        errorMessage: l10n.faceRetouchFailedMessage,
      );
    }
  }

  Future<void> saveCurrentImage() async {
    final AppLocalizations l10n = AppLocalizations.current;
    final EditorSession? session = state.session;
    if (session == null || state.isBusy) {
      return;
    }
    final int operationVersion = _beginOperation();

    state = state.copyWith(
      status: EditorStatus.saving,
      busyMessage: l10n.busyPreparingSaveImage,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      final Uint8List output = await _buildOutputBytes(session);
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      await _exportRepository.saveJpeg(output);
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      state = state.copyWith(
        status: EditorStatus.ready,
        clearBusyMessage: true,
        clearInfoMessage: true,
      );
    } catch (error) {
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      if (error is AppException) {
        state = state.copyWith(
          status: EditorStatus.ready,
          clearBusyMessage: true,
          errorMessage: error.userMessage,
        );
        return;
      }
      state = state.copyWith(
        status: EditorStatus.ready,
        clearBusyMessage: true,
        errorMessage: l10n.saveFailedMessage,
      );
    }
  }

  Future<void> shareCurrentImage() async {
    final AppLocalizations l10n = AppLocalizations.current;
    final EditorSession? session = state.session;
    if (session == null || state.isBusy) {
      return;
    }
    final int operationVersion = _beginOperation();

    state = state.copyWith(
      status: EditorStatus.sharing,
      busyMessage: l10n.busyPreparingShareImage,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      final Uint8List output = await _buildOutputBytes(session);
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      await _exportRepository.shareImage(output, text: l10n.sharePhotoText);
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      state = state.copyWith(
        status: EditorStatus.ready,
        clearBusyMessage: true,
        infoMessage: l10n.shareSheetOpenedMessage,
      );
    } catch (error) {
      if (!_isOperationActive(operationVersion)) {
        return;
      }
      if (error is AppException) {
        state = state.copyWith(
          status: EditorStatus.ready,
          clearBusyMessage: true,
          errorMessage: error.userMessage,
        );
        return;
      }
      state = state.copyWith(
        status: EditorStatus.ready,
        clearBusyMessage: true,
        errorMessage: l10n.shareFailedMessage,
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

  int _beginOperation() {
    _operationVersion += 1;
    return _operationVersion;
  }

  bool _isOperationActive(int version) {
    return version == _operationVersion;
  }

  void _invalidatePendingOperations() {
    _operationVersion += 1;
  }
}
