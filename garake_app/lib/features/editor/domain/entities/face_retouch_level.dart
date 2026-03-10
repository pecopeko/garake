// Defines selectable face-retouch strengths for the post-shot beauty editor.
/*
Dependency Memo
- Depends on: Dart enum support only.
- Requires methods: none.
- Provides methods: FaceRetouchLevel.menuLabel, FaceRetouchLevel.statusCode, FaceRetouchLevel.isEnabled.
*/
enum FaceRetouchLevel {
  off(menuLabel: 'OFF', statusCode: 'B:0'),
  low(menuLabel: '弱', statusCode: 'B:1'),
  medium(menuLabel: '中', statusCode: 'B:2'),
  high(menuLabel: '強', statusCode: 'B:3');

  const FaceRetouchLevel({required this.menuLabel, required this.statusCode});

  final String menuLabel;
  final String statusCode;

  bool get isEnabled => this != FaceRetouchLevel.off;
}
