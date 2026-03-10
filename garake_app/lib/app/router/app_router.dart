// Defines route paths and screen builders for the app.
/*
Dependency Memo
- Depends on: launch screen and editor screen.
- Requires methods: LaunchScreen constructor, EditorScreen constructor, PageRouteBuilder constructor.
- Provides methods: AppRouter.routes().
*/
import 'package:flutter/material.dart';

import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/launch/presentation/screens/launch_screen.dart';

class AppRouter {
  const AppRouter._();

  static const String launchRoute = '/';
  static const String homeRoute = '/home';

  static Map<String, WidgetBuilder> routes() {
    return <String, WidgetBuilder>{
      launchRoute: (_) => LaunchScreen(
        nextRouteBuilder: () => PageRouteBuilder<void>(
          settings: const RouteSettings(name: homeRoute),
          pageBuilder:
              (
                BuildContext context,
                Animation<double> _,
                Animation<double> __,
              ) {
                return const EditorScreen();
              },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      ),
      homeRoute: (_) => const EditorScreen(),
    };
  }
}
