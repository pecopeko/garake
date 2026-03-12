// Coordinates in-shell photo capture and disposable-camera video finishing without leaking camera details into the screen widget.
/*
Dependency Memo
- Depends on: camera.dart for capture hardware access, export_repository.dart for save/share output, video_style_renderer.dart for retro finishing, and app_exception.dart for user-facing failures.
- Requires methods: availableCameras(), CameraController.initialize(), setFlashMode(), prepareForVideoRecording(), takePicture(), startVideoRecording(), stopVideoRecording(), renderDisposableCameraVideo(), saveVideoFile(), shareVideoFile().
- Provides methods: enter(), leave(), toggleLensDirection(), takePhoto(), startVideoRecording(), stopVideoRecording(), saveRecordedVideo(), shareRecordedVideo(), deleteRecordedVideo().
*/
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/save_result.dart';
import '../../domain/repositories/export_repository.dart';
import '../../domain/repositories/video_style_renderer.dart';

enum LiveCaptureMode { photo, video }

class LiveCaptureCoordinator {
  LiveCaptureCoordinator({
    required ExportRepository exportRepository,
    required VideoStyleRenderer videoStyleRenderer,
  }) : _exportRepository = exportRepository,
       _videoStyleRenderer = videoStyleRenderer;

  final ExportRepository _exportRepository;
  final VideoStyleRenderer _videoStyleRenderer;

  CameraController? _controller;
  LiveCaptureMode? _mode;
  bool _isInitializing = false;
  bool _isCapturingStill = false;
  String? _errorMessage;
  XFile? _recordedVideoFile;
  CameraLensDirection _lensDirection = CameraLensDirection.back;

  CameraController? get controller => _controller;
  LiveCaptureMode? get mode => _mode;
  bool get isActive => _mode != null;
  bool get isPhotoMode => _mode == LiveCaptureMode.photo;
  bool get isVideoMode => _mode == LiveCaptureMode.video;
  bool get isInitializing => _isInitializing;
  bool get isCapturingStill => _isCapturingStill;
  String? get errorMessage => _errorMessage;
  bool get hasRecordedVideo => _recordedVideoFile != null;
  CameraLensDirection get lensDirection => _lensDirection;
  bool get isFrontLens => _lensDirection == CameraLensDirection.front;
  String get lensDirectionLabel =>
      AppLocalizations.current.lensDirectionLabel(isFront: isFrontLens);
  String get lensToggleLabel =>
      AppLocalizations.current.lensToggleLabel(isFront: isFrontLens);

  bool get isRecordingVideo {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return false;
    }
    return cameraController.value.isRecordingVideo;
  }

  bool get canOpenSaveSharePanel =>
      isVideoMode && !isRecordingVideo && hasRecordedVideo;

  String get shellModeLabel {
    final AppLocalizations l10n = AppLocalizations.current;
    if (isVideoMode) {
      return l10n.liveShellModeVideo;
    }
    return l10n.liveShellModeCamera;
  }

  String get selectionLabel {
    final AppLocalizations l10n = AppLocalizations.current;
    if (_errorMessage != null) {
      return l10n.liveSelectionError;
    }
    if (isVideoMode) {
      if (isRecordingVideo) {
        return l10n.liveSelectionRecording;
      }
      if (hasRecordedVideo) {
        return l10n.liveSelectionClip;
      }
    }
    return isVideoMode ? l10n.liveSelectionStandby : l10n.liveSelectionShot;
  }

  String get primaryActionLabel {
    final AppLocalizations l10n = AppLocalizations.current;
    if (isVideoMode) {
      if (isRecordingVideo) {
        return l10n.liveStopAction;
      }
      if (hasRecordedVideo) {
        return l10n.liveRetryVideoAction;
      }
    }
    return isVideoMode ? l10n.liveVideoAction : l10n.livePhotoAction;
  }

  String get overlayStatusLabel {
    final AppLocalizations l10n = AppLocalizations.current;
    if (isVideoMode && isRecordingVideo) {
      return l10n.liveSelectionRecording;
    }
    if (isVideoMode && hasRecordedVideo) {
      return l10n.liveStatusClipReady;
    }
    return isVideoMode ? l10n.liveStatusVideo : l10n.liveStatusPhoto;
  }

  String get overlayHintLabel {
    final AppLocalizations l10n = AppLocalizations.current;
    if (isVideoMode && isRecordingVideo) {
      return l10n.liveHintStopRecording;
    }
    if (isVideoMode && hasRecordedVideo) {
      return l10n.liveHintSaveOrShare;
    }
    return isVideoMode ? l10n.liveHintRecordVideo : l10n.liveHintTakePhoto;
  }

  Future<void> enter(LiveCaptureMode mode) async {
    await _openCamera(
      mode: mode,
      lensDirection: _lensDirection,
      clearRecordedVideo: true,
    );
  }

  Future<bool> toggleLensDirection() async {
    final AppLocalizations l10n = AppLocalizations.current;
    final LiveCaptureMode? currentMode = _mode;
    if (currentMode == null || _isInitializing || _isCapturingStill) {
      return false;
    }

    if (isRecordingVideo) {
      _errorMessage = l10n.cannotSwitchWhileRecordingMessage;
      return false;
    }

    if (hasRecordedVideo) {
      _errorMessage = l10n.cannotSwitchWithUnsavedClipMessage;
      return false;
    }

    final CameraLensDirection nextLensDirection =
        _lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final List<CameraDescription> cameras = await availableCameras();
    final bool hasRequestedLens = cameras.any(
      (CameraDescription camera) => camera.lensDirection == nextLensDirection,
    );
    if (!hasRequestedLens) {
      _errorMessage = l10n.unavailableCameraMessage(
        isFront: nextLensDirection == CameraLensDirection.front,
      );
      return false;
    }

    await _openCamera(
      mode: currentMode,
      lensDirection: nextLensDirection,
      clearRecordedVideo: false,
    );
    return errorMessage == null;
  }

  Future<void> leave() async {
    await _disposeController();
    await _clearRecordedVideoFile();
    _mode = null;
    _isInitializing = false;
    _isCapturingStill = false;
    _errorMessage = null;
    _lensDirection = CameraLensDirection.back;
  }

  Future<Uint8List> takePhoto() async {
    final AppLocalizations l10n = AppLocalizations.current;
    if (!isPhotoMode) {
      throw AppException(l10n.photoModeOnlyMessage);
    }

    final CameraController cameraController = _requireReadyController();
    _isCapturingStill = true;
    _errorMessage = null;

    try {
      await _disableFlash(cameraController);
      final XFile imageFile = await cameraController.takePicture();
      return imageFile.readAsBytes();
    } catch (_) {
      _errorMessage = l10n.takePhotoFailedMessage;
      rethrow;
    } finally {
      _isCapturingStill = false;
    }
  }

  Future<void> startVideoRecording() async {
    final AppLocalizations l10n = AppLocalizations.current;
    if (!isVideoMode) {
      throw AppException(l10n.videoModeOnlyMessage);
    }

    final CameraController cameraController = _requireReadyController();
    if (cameraController.value.isRecordingVideo) {
      return;
    }

    _errorMessage = null;
    await _clearRecordedVideoFile();

    try {
      await _disableFlash(cameraController);
      await cameraController.startVideoRecording();
    } catch (_) {
      _errorMessage = l10n.startRecordingFailedMessage;
      rethrow;
    }
  }

  Future<XFile> stopVideoRecording() async {
    final AppLocalizations l10n = AppLocalizations.current;
    if (!isVideoMode) {
      throw AppException(l10n.videoModeOnlyMessage);
    }

    final CameraController cameraController = _requireReadyController();
    if (!cameraController.value.isRecordingVideo) {
      throw AppException(l10n.recordingNotStartedMessage);
    }

    _errorMessage = null;

    XFile? rawFile;
    try {
      rawFile = await cameraController.stopVideoRecording();
      final XFile finishedFile = await _finishRecordedVideo(rawFile);
      _recordedVideoFile = finishedFile;
      return finishedFile;
    } catch (_) {
      await _deleteCapturedRawFile(rawFile);
      _errorMessage = l10n.finishVideoStyleFailedMessage;
      rethrow;
    }
  }

  Future<SaveResult> saveRecordedVideo() {
    final XFile file = _requireRecordedVideo();
    return _exportRepository.saveVideoFile(file.path);
  }

  Future<void> shareRecordedVideo() {
    final XFile file = _requireRecordedVideo();
    return _exportRepository.shareVideoFile(
      file.path,
      text: AppLocalizations.current.shareVideoText,
    );
  }

  Future<void> deleteRecordedVideo() async {
    await _clearRecordedVideoFile();
    _errorMessage = null;
  }

  Future<void> _disposeController() async {
    final CameraController? controller = _controller;
    _controller = null;

    if (controller == null) {
      return;
    }

    try {
      if (controller.value.isRecordingVideo) {
        await controller.stopVideoRecording();
      }
    } catch (_) {
      // 破棄時は録画中断エラーを握りつぶして復帰優先にする。
    }

    await controller.dispose();
  }

  Future<void> _openCamera({
    required LiveCaptureMode mode,
    required CameraLensDirection lensDirection,
    required bool clearRecordedVideo,
  }) async {
    final AppLocalizations l10n = AppLocalizations.current;
    if (_isInitializing) {
      return;
    }

    await _disposeController();
    if (clearRecordedVideo) {
      await _clearRecordedVideoFile();
    }

    _mode = mode;
    _isInitializing = true;
    _isCapturingStill = false;
    _errorMessage = null;
    _lensDirection = lensDirection;

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw AppException(l10n.noCameraFoundMessage);
      }

      final CameraDescription selectedCamera = cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == lensDirection,
        orElse: () => cameras.first,
      );

      final CameraController controller = CameraController(
        selectedCamera,
        mode == LiveCaptureMode.video
            ? ResolutionPreset.medium
            : ResolutionPreset.high,
        enableAudio: mode == LiveCaptureMode.video,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await _disableFlash(controller);
      if (mode == LiveCaptureMode.video) {
        await controller.prepareForVideoRecording();
      }

      _controller = controller;
      _lensDirection = selectedCamera.lensDirection;
    } catch (_) {
      _errorMessage = mode == LiveCaptureMode.video
          ? l10n.openVideoCameraFailedMessage
          : l10n.openCameraFailedMessage;
    } finally {
      _isInitializing = false;
    }
  }

  CameraController _requireReadyController() {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      throw AppException(AppLocalizations.current.cameraNotReadyMessage);
    }
    return cameraController;
  }

  XFile _requireRecordedVideo() {
    final XFile? file = _recordedVideoFile;
    if (file == null) {
      throw AppException(AppLocalizations.current.recordVideoFirstMessage);
    }
    return file;
  }

  Future<void> _clearRecordedVideoFile() async {
    final XFile? file = _recordedVideoFile;
    _recordedVideoFile = null;
    await _deleteFileAtPath(file?.path);
  }

  Future<XFile> _finishRecordedVideo(XFile rawFile) async {
    final String styledPath = await _videoStyleRenderer
        .renderDisposableCameraVideo(rawFile.path);
    if (styledPath != rawFile.path) {
      await _deleteFileAtPath(rawFile.path);
    }
    return XFile(styledPath);
  }

  Future<void> _deleteCapturedRawFile(XFile? rawFile) {
    return _deleteFileAtPath(rawFile?.path);
  }

  Future<void> _deleteFileAtPath(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }

    final File ioFile = File(path);
    if (await ioFile.exists()) {
      await ioFile.delete();
    }
  }

  Future<void> _disableFlash(CameraController controller) async {
    // フラッシュ自動発光を防ぐため常にオフを試みる。
    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {
      // 非対応端末でも撮影自体は継続する。
    }
  }
}
