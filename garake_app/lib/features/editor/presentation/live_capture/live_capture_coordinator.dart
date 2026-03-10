// Coordinates in-shell photo capture and video recording without leaking camera details into the screen widget.
/*
Dependency Memo
- Depends on: camera.dart for capture hardware access, export_repository.dart for save/share output, and app_exception.dart for user-facing failures.
- Requires methods: availableCameras(), CameraController.initialize(), prepareForVideoRecording(), takePicture(), startVideoRecording(), stopVideoRecording(), saveVideoFile(), shareVideoFile().
- Provides methods: enter(), leave(), takePhoto(), startVideoRecording(), stopVideoRecording(), saveRecordedVideo(), shareRecordedVideo(), deleteRecordedVideo().
*/
import 'dart:typed_data';

import 'package:camera/camera.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/save_result.dart';
import '../../domain/repositories/export_repository.dart';

enum LiveCaptureMode {
  photo(
    shellModeLabel: 'CAM',
    selectionLabel: 'SHOT',
    primaryActionLabel: '撮影',
    overlayStatusLabel: 'PHOTO',
    overlayHintLabel: 'OKで撮影',
  ),
  video(
    shellModeLabel: 'MOV',
    selectionLabel: 'STBY',
    primaryActionLabel: '録画',
    overlayStatusLabel: 'VIDEO',
    overlayHintLabel: 'OKで録画',
  );

  const LiveCaptureMode({
    required this.shellModeLabel,
    required this.selectionLabel,
    required this.primaryActionLabel,
    required this.overlayStatusLabel,
    required this.overlayHintLabel,
  });

  final String shellModeLabel;
  final String selectionLabel;
  final String primaryActionLabel;
  final String overlayStatusLabel;
  final String overlayHintLabel;
}

class LiveCaptureCoordinator {
  LiveCaptureCoordinator({required ExportRepository exportRepository})
    : _exportRepository = exportRepository;

  final ExportRepository _exportRepository;

  CameraController? _controller;
  LiveCaptureMode? _mode;
  bool _isInitializing = false;
  bool _isCapturingStill = false;
  String? _errorMessage;
  XFile? _recordedVideoFile;

  CameraController? get controller => _controller;
  LiveCaptureMode? get mode => _mode;
  bool get isActive => _mode != null;
  bool get isPhotoMode => _mode == LiveCaptureMode.photo;
  bool get isVideoMode => _mode == LiveCaptureMode.video;
  bool get isInitializing => _isInitializing;
  bool get isCapturingStill => _isCapturingStill;
  String? get errorMessage => _errorMessage;
  bool get hasRecordedVideo => _recordedVideoFile != null;

  bool get isRecordingVideo {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return false;
    }
    return cameraController.value.isRecordingVideo;
  }

  bool get canOpenSaveSharePanel =>
      isVideoMode && !isRecordingVideo && hasRecordedVideo;

  String get shellModeLabel => _mode?.shellModeLabel ?? 'CAM';

  String get selectionLabel {
    if (_errorMessage != null) {
      return 'ERR';
    }
    if (isVideoMode) {
      if (isRecordingVideo) {
        return 'REC';
      }
      if (hasRecordedVideo) {
        return 'CLIP';
      }
    }
    return _mode?.selectionLabel ?? 'SHOT';
  }

  String get primaryActionLabel {
    if (isVideoMode) {
      if (isRecordingVideo) {
        return '停止';
      }
      if (hasRecordedVideo) {
        return '再録画';
      }
    }
    return _mode?.primaryActionLabel ?? '撮影';
  }

  String get overlayStatusLabel {
    if (isVideoMode && isRecordingVideo) {
      return 'REC';
    }
    if (isVideoMode && hasRecordedVideo) {
      return 'CLIP READY';
    }
    return _mode?.overlayStatusLabel ?? 'PHOTO';
  }

  String get overlayHintLabel {
    if (isVideoMode && isRecordingVideo) {
      return 'OKで停止';
    }
    if (isVideoMode && hasRecordedVideo) {
      return '保存/シェアできます';
    }
    return _mode?.overlayHintLabel ?? 'OKで撮影';
  }

  Future<void> enter(LiveCaptureMode mode) async {
    if (_isInitializing) {
      return;
    }

    await _disposeController();

    _mode = mode;
    _isInitializing = true;
    _isCapturingStill = false;
    _recordedVideoFile = null;
    _errorMessage = null;

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw const AppException('カメラが見つかりません。');
      }

      final CameraDescription selectedCamera = cameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final CameraController controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: mode == LiveCaptureMode.video,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (mode == LiveCaptureMode.video) {
        await controller.prepareForVideoRecording();
      }

      _controller = controller;
    } catch (_) {
      _errorMessage = mode == LiveCaptureMode.video
          ? '動画カメラを起動できませんでした。権限と端末設定を確認してください。'
          : 'カメラを起動できませんでした。権限と端末設定を確認してください。';
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> leave() async {
    await _disposeController();
    _mode = null;
    _isInitializing = false;
    _isCapturingStill = false;
    _recordedVideoFile = null;
    _errorMessage = null;
  }

  Future<Uint8List> takePhoto() async {
    if (!isPhotoMode) {
      throw const AppException('写真モードではありません。');
    }

    final CameraController cameraController = _requireReadyController();
    _isCapturingStill = true;
    _errorMessage = null;

    try {
      final XFile imageFile = await cameraController.takePicture();
      return imageFile.readAsBytes();
    } catch (_) {
      _errorMessage = '撮影に失敗しました。もう一度お試しください。';
      rethrow;
    } finally {
      _isCapturingStill = false;
    }
  }

  Future<void> startVideoRecording() async {
    if (!isVideoMode) {
      throw const AppException('動画モードではありません。');
    }

    final CameraController cameraController = _requireReadyController();
    if (cameraController.value.isRecordingVideo) {
      return;
    }

    _errorMessage = null;
    _recordedVideoFile = null;

    try {
      await cameraController.startVideoRecording();
    } catch (_) {
      _errorMessage = '録画を開始できませんでした。';
      rethrow;
    }
  }

  Future<XFile> stopVideoRecording() async {
    if (!isVideoMode) {
      throw const AppException('動画モードではありません。');
    }

    final CameraController cameraController = _requireReadyController();
    if (!cameraController.value.isRecordingVideo) {
      throw const AppException('録画はまだ始まっていません。');
    }

    _errorMessage = null;

    try {
      final XFile file = await cameraController.stopVideoRecording();
      _recordedVideoFile = file;
      return file;
    } catch (_) {
      _errorMessage = '録画の停止に失敗しました。';
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
      text: 'ガラケーカメラで動画を撮りました',
    );
  }

  void deleteRecordedVideo() {
    _recordedVideoFile = null;
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

  CameraController _requireReadyController() {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      throw const AppException('カメラの準備ができていません。');
    }
    return cameraController;
  }

  XFile _requireRecordedVideo() {
    final XFile? file = _recordedVideoFile;
    if (file == null) {
      throw const AppException('先に動画を録画してください。');
    }
    return file;
  }
}
