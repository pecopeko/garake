// Defines typed application errors to control user-facing failure messages.
/*
Dependency Memo
- Depends on: Dart core exception types only.
- Requires methods: none.
- Provides methods: AppException.userMessage.
*/
class AppException implements Exception {
  const AppException(this.userMessage);

  final String userMessage;

  @override
  String toString() => 'AppException($userMessage)';
}
