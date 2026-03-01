// Carries save output metadata returned by persistence operations.
/*
Dependency Memo
- Depends on: Dart core DateTime and String types.
- Requires methods: none.
- Provides methods: SaveResult constructor.
*/
class SaveResult {
  const SaveResult({required this.filePath, required this.createdAt});

  final String filePath;
  final DateTime createdAt;
}
