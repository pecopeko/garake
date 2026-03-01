// Defines route paths and screen builders for the app.
/*
Dependency Memo
- Depends on: editor screen.
- Requires methods: EditorScreen constructor.
- Provides methods: AppRouter.routes().
*/
import 'package:flutter/material.dart';

import '../../features/editor/presentation/screens/editor_screen.dart';

class AppRouter {
  const AppRouter._();

  static const String homeRoute = '/';

  static Map<String, WidgetBuilder> routes() {
    return <String, WidgetBuilder>{homeRoute: (_) => const EditorScreen()};
  }
}
