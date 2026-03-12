// Defines the simple face-retouch toggle used by the beauty editor.
/*
Dependency Memo
- Depends on: Dart enum support only.
- Requires methods: none.
- Provides methods: FaceRetouchLevel.isEnabled.
*/
enum FaceRetouchLevel {
  off,
  cute;

  bool get isEnabled => this != FaceRetouchLevel.off;
}
