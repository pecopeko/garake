// Moves live-camera lifecycle and transient editor messages out of editor_screen.dart so the screen stays within size limits.
/*
Dependency Memo
- Depends on: editor_screen.dart state fields, camera.dart APIs, and editor controller callbacks.
- Requires methods: availableCameras(), CameraController.initialize(), CameraController.takePicture(), EditorController.startSessionFromBytes(), State.setState().
- Provides methods: _enterLiveCameraMode(), _leaveLiveCameraMode(), _captureFromLiveCamera(), _disposeLiveCameraController(), _handleStateMessages(), _showSystemMessage().
*/
part of 'editor_screen.dart';

Future<void> _enterLiveCameraMode(_EditorScreenState state) async {
  if (state._isInitializingCamera) {
    return;
  }

  await _disposeLiveCameraController(state);
  if (!state.mounted) {
    return;
  }

  state._applyUiUpdate(() {
    state._isLiveCameraMode = true;
    state._isInitializingCamera = true;
    state._isCapturing = false;
    state._cameraErrorMessage = null;
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

    if (!state.mounted) {
      await controller.dispose();
      return;
    }

    state._applyUiUpdate(() {
      state._liveCameraController = controller;
      state._isInitializingCamera = false;
    });
  } catch (_) {
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {
      state._isInitializingCamera = false;
      state._cameraErrorMessage = 'カメラを起動できませんでした。権限と端末設定を確認してください。';
    });
  }
}

Future<void> _leaveLiveCameraMode(_EditorScreenState state) async {
  await _disposeLiveCameraController(state);
  if (!state.mounted) {
    return;
  }

  state._applyUiUpdate(() {
    state._isLiveCameraMode = false;
    state._isInitializingCamera = false;
    state._isCapturing = false;
    state._cameraErrorMessage = null;
  });
}

Future<void> _captureFromLiveCamera(
  _EditorScreenState state,
  EditorController controller,
) async {
  if (!state._isLiveCameraMode ||
      state._isInitializingCamera ||
      state._isCapturing) {
    return;
  }

  final CameraController? cameraController = state._liveCameraController;
  if (cameraController == null || !cameraController.value.isInitialized) {
    state._applyUiUpdate(() {
      state._cameraErrorMessage = 'カメラの準備ができていません。';
    });
    return;
  }

  state._applyUiUpdate(() {
    state._isCapturing = true;
    state._cameraErrorMessage = null;
  });

  try {
    final XFile imageFile = await cameraController.takePicture();
    final bytes = await imageFile.readAsBytes();

    await _leaveLiveCameraMode(state);
    if (!state.mounted) {
      return;
    }

    await controller.startSessionFromBytes(bytes);
  } catch (_) {
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {
      state._isCapturing = false;
      state._cameraErrorMessage = '撮影に失敗しました。もう一度お試しください。';
    });
  }
}

Future<void> _disposeLiveCameraController(_EditorScreenState state) async {
  final CameraController? controller = state._liveCameraController;
  state._liveCameraController = null;
  if (controller != null) {
    await controller.dispose();
  }
}

void _handleStateMessages(
  _EditorScreenState state,
  EditorState? previous,
  EditorState next,
) {
  final String? error = next.errorMessage;
  final String? info = next.infoMessage;

  if (error != null && error != previous?.errorMessage) {
    _showSystemMessage(state, error);
    state.ref.read(editorControllerProvider.notifier).clearMessages();
    return;
  }
  if (info != null && info != previous?.infoMessage) {
    _showSystemMessage(state, info);
    state.ref.read(editorControllerProvider.notifier).clearMessages();
  }
}

void _showSystemMessage(_EditorScreenState state, String message) {
  state._systemMessageTimer?.cancel();
  if (!state.mounted) {
    return;
  }
  state._applyUiUpdate(() {
    state._systemMessage = message;
  });
  state._systemMessageTimer = Timer(const Duration(milliseconds: 1800), () {
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {
      state._systemMessage = null;
    });
  });
}
