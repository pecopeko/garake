// Immutable UI state for editor flow, async status, keypad mode, and transient messages.
/*
Dependency Memo
- Depends on: editor_session.dart for loaded editing context.
- Requires methods: EditorSession.copyWith().
- Provides methods: EditorState.copyWith().
*/
import '../domain/entities/editor_session.dart';

enum EditorStatus { idle, picking, processing, ready, saving, sharing, error }

enum KeypadMode { move, scale }

class EditorState {
  const EditorState({
    this.status = EditorStatus.idle,
    this.keypadMode = KeypadMode.move,
    this.session,
    this.busyMessage,
    this.errorMessage,
    this.infoMessage,
  });

  final EditorStatus status;
  final KeypadMode keypadMode;
  final EditorSession? session;
  final String? busyMessage;
  final String? errorMessage;
  final String? infoMessage;

  bool get hasSession => session != null;

  bool get isBusy {
    return status == EditorStatus.picking ||
        status == EditorStatus.processing ||
        status == EditorStatus.saving ||
        status == EditorStatus.sharing;
  }

  EditorState copyWith({
    EditorStatus? status,
    KeypadMode? keypadMode,
    EditorSession? session,
    String? busyMessage,
    String? errorMessage,
    String? infoMessage,
    bool clearSession = false,
    bool clearBusyMessage = false,
    bool clearErrorMessage = false,
    bool clearInfoMessage = false,
  }) {
    return EditorState(
      status: status ?? this.status,
      keypadMode: keypadMode ?? this.keypadMode,
      session: clearSession ? null : (session ?? this.session),
      busyMessage: clearBusyMessage ? null : (busyMessage ?? this.busyMessage),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
    );
  }
}
