// Entry point that boots the Riverpod-enabled Garake app.
/*
Dependency Memo
- Depends on: lib/app/app.dart (builds top-level MaterialApp).
- Requires methods: runApp() from Flutter SDK.
- Provides methods: main().
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: GarakeApp()));
}
