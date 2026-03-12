// Root app widget that wires theme and navigation.
/*
Dependency Memo
- Depends on: lib/app/router/app_router.dart (route table), lib/app/theme/app_theme.dart (visual style).
- Requires methods: AppRouter.routes(), AppTheme.build().
- Provides methods: GarakeApp.build().
*/
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_localizations.dart';
import 'layout/platform_phone_viewport.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class GarakeApp extends StatelessWidget {
  const GarakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      initialRoute: AppRouter.launchRoute,
      routes: AppRouter.routes(),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) {
        // Webではスマホ幅に寄せて、Figmaと同じ見た目で調整しやすくする。
        return PlatformPhoneViewport(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
