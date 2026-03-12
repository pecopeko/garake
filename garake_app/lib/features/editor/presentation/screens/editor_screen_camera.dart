// Moves live capture lifecycle and disposable-camera video finishing messages out of editor_screen.dart so the screen stays compact.
/*
Dependency Memo
- Depends on: editor_screen.dart state fields, live_capture_coordinator.dart, and editor controller callbacks.
- Requires methods: LiveCaptureCoordinator.enter(), leave(), toggleLensDirection(), takePhoto(), startVideoRecording(), stopVideoRecording(), saveRecordedVideo(), shareRecordedVideo(), deleteRecordedVideo(), EditorController.startSessionFromBytes(), EditorController.clearMessages(), and State.setState().
 - Provides methods: _enterLiveCaptureMode(), _toggleLiveCaptureLens(), _leaveLiveCaptureMode(), _handleLiveCapturePrimaryAction(), _runLiveCaptureStop(), _saveRecordedVideo(), _shareRecordedVideo(), _deleteRecordedVideo(), _handleStateMessages(), _showSystemMessage().
*/
part of 'editor_screen.dart';

Future<void> _enterLiveCaptureMode(
  _EditorScreenState state,
  LiveCaptureMode mode,
) async {
  if (state._isLiveCaptureActionBusy || state._liveCapture.isInitializing) {
    return;
  }

  state._closePanel();
  await state._liveCapture.enter(mode);
  if (!state.mounted) {
    return;
  }

  state._applyUiUpdate(() {
    state._liveCaptureBusyLabel = null;
  });
}

Future<void> _leaveLiveCaptureMode(_EditorScreenState state) async {
  state._closePanel();
  await state._liveCapture.leave();
  if (!state.mounted) {
    return;
  }

  state._applyUiUpdate(() {
    state._isLiveCaptureActionBusy = false;
    state._liveCaptureBusyLabel = null;
  });
}

Future<bool> _toggleLiveCaptureLens(_EditorScreenState state) async {
  if (state._isLiveCaptureActionBusy || state._liveCapture.isInitializing) {
    return false;
  }

  final bool didToggle = await state._liveCapture.toggleLensDirection();
  if (!state.mounted) {
    return false;
  }

  state._applyUiUpdate(() {});
  if (!didToggle && state._liveCapture.errorMessage != null) {
    _showSystemMessage(state, state._liveCapture.errorMessage!);
  }
  return didToggle;
}

Future<void> _handleLiveCapturePrimaryAction(
  _EditorScreenState state,
  EditorController controller,
) async {
  final AppLocalizations l10n = AppLocalizations.current;
  if (state._isLiveCaptureActionBusy || state._liveCapture.isInitializing) {
    return;
  }

  if (state._liveCapture.isPhotoMode) {
    await _capturePhotoFromLivePreview(state, controller);
    return;
  }

  try {
    if (state._liveCapture.isRecordingVideo) {
      await _runLiveCaptureStop(state);
      return;
    }

    await state._liveCapture.startVideoRecording();
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {});
    _showSystemMessage(state, l10n.recordingStartedMessage);
  } on AppException catch (error) {
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {});
    _showSystemMessage(state, error.userMessage);
  } catch (_) {
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {});
    _showSystemMessage(
      state,
      state._liveCapture.errorMessage ?? l10n.genericVideoActionFailedMessage,
    );
  }
}

Future<void> _runLiveCaptureStop(_EditorScreenState state) async {
  final AppLocalizations l10n = AppLocalizations.current;
  state._applyUiUpdate(() {
    state._isLiveCaptureActionBusy = true;
    state._liveCaptureBusyLabel = l10n.busyAutoSavingVideo;
  });

  try {
    await state._liveCapture.stopVideoRecording();
    String? autoSaveFailureMessage;
    try {
      await state._liveCapture.saveRecordedVideo();
    } on AppException catch (error) {
      autoSaveFailureMessage = l10n.videoAutoSaveRetryMessage(
        error.userMessage,
      );
    } catch (_) {
      autoSaveFailureMessage = l10n.videoAutoSaveRetryFallbackMessage;
    }
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {});
    if (autoSaveFailureMessage != null) {
      _showSystemMessage(state, autoSaveFailureMessage);
    }
  } finally {
    if (state.mounted) {
      state._applyUiUpdate(() {
        state._isLiveCaptureActionBusy = false;
        state._liveCaptureBusyLabel = null;
      });
    }
  }
}

Future<void> _capturePhotoFromLivePreview(
  _EditorScreenState state,
  EditorController controller,
) async {
  final AppLocalizations l10n = AppLocalizations.current;
  try {
    final bytes = await state._liveCapture.takePhoto();
    await state._liveCapture.leave();
    if (!state.mounted) {
      return;
    }

    state._applyUiUpdate(() {
      state._liveCaptureBusyLabel = null;
    });
    await controller.startSessionFromBytes(
      bytes,
      busyMessage: l10n.busyProcessingPhoto,
      showLoadedMessage: false,
    );
    if (!state.mounted) {
      return;
    }

    await controller.saveCurrentImage();
  } on AppException catch (error) {
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {});
    _showSystemMessage(state, error.userMessage);
  } catch (_) {
    if (!state.mounted) {
      return;
    }
    state._applyUiUpdate(() {});
    _showSystemMessage(
      state,
      state._liveCapture.errorMessage ?? l10n.takePhotoFailedMessage,
    );
  }
}

Future<void> _saveRecordedVideo(_EditorScreenState state) {
  return _runLiveCaptureAction(
    state,
    busyLabel: AppLocalizations.current.busySavingVideo,
    action: () => state._liveCapture.saveRecordedVideo(),
  );
}

Future<void> _shareRecordedVideo(_EditorScreenState state) {
  final AppLocalizations l10n = AppLocalizations.current;
  return _runLiveCaptureAction(
    state,
    busyLabel: l10n.busyOpeningShareSheet,
    action: () async {
      await state._liveCapture.shareRecordedVideo();
      _showSystemMessage(state, l10n.shareSheetOpenedMessage);
    },
  );
}

Future<void> _deleteRecordedVideo(_EditorScreenState state) {
  final AppLocalizations l10n = AppLocalizations.current;
  return _runLiveCaptureAction(
    state,
    busyLabel: l10n.busyDeletingVideo,
    action: () async {
      await state._liveCapture.deleteRecordedVideo();
      _showSystemMessage(state, l10n.recordedVideoDeletedMessage);
    },
  );
}

Future<void> _runLiveCaptureAction(
  _EditorScreenState state, {
  required String busyLabel,
  required Future<void> Function() action,
}) async {
  if (state._isLiveCaptureActionBusy) {
    return;
  }

  state._applyUiUpdate(() {
    state._isLiveCaptureActionBusy = true;
    state._liveCaptureBusyLabel = busyLabel;
  });

  try {
    await action();
  } on AppException catch (error) {
    if (state.mounted) {
      _showSystemMessage(state, error.userMessage);
    }
  } catch (_) {
    if (state.mounted) {
      _showSystemMessage(
        state,
        state._liveCapture.errorMessage ??
            AppLocalizations.current.genericVideoProcessFailedMessage,
      );
    }
  } finally {
    if (state.mounted) {
      state._applyUiUpdate(() {
        state._isLiveCaptureActionBusy = false;
        state._liveCaptureBusyLabel = null;
      });
    }
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
