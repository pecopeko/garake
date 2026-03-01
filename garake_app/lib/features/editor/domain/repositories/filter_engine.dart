// Defines the contract for converting a raw image to Garake style output.
/*
Dependency Memo
- Depends on: filter_config.dart for tuning parameters.
- Requires methods: none.
- Provides methods: applyGarakeFilter().
*/
import 'dart:typed_data';

import '../entities/filter_config.dart';

abstract class FilterEngine {
  Future<Uint8List> applyGarakeFilter(
    Uint8List input,
    FilterConfig config,
    DateTime now,
  );
}
