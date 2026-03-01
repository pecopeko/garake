// Enumerates image source options selectable from the menu key.
/*
Dependency Memo
- Depends on: Dart enum features only.
- Requires methods: none.
- Provides methods: ImageInputType.label.
*/
enum ImageInputType {
  camera('撮影する'),
  gallery('アルバムから選ぶ');

  const ImageInputType(this.label);

  final String label;
}
