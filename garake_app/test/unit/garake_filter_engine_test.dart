// Verifies Garake filter engine output shape and visible transformations.
/*
Dependency Memo
- Depends on: garake_filter_engine_impl.dart and filter_config.dart.
- Requires methods: applyGarakeFilter().
- Provides methods: main() tests.
*/
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:garake_app/core/image_processing/garake_filter_engine_impl.dart';
import 'package:garake_app/features/editor/domain/entities/filter_config.dart';

void main() {
  test(
    'applyGarakeFilter keeps dimensions and adds transform artifacts',
    () async {
      final GarakeFilterEngineImpl engine = GarakeFilterEngineImpl();
      final img.Image source = img.Image(width: 180, height: 120);

      for (int y = 0; y < source.height; y++) {
        for (int x = 0; x < source.width; x++) {
          source.setPixelRgba(x, y, x % 255, y % 255, (x + y) % 255, 255);
        }
      }

      final Uint8List input = Uint8List.fromList(
        img.encodeJpg(source, quality: 95),
      );
      final Uint8List output = await engine.applyGarakeFilter(
        input,
        FilterConfig.v1,
        DateTime(2026, 2, 22),
      );

      final img.Image? decoded = img.decodeImage(output);
      expect(decoded, isNotNull);
      expect(decoded!.width, source.width);
      expect(decoded.height, source.height);
      expect(output, isNot(equals(input)));
    },
  );

  test(
    'filtered image retains reasonable brightness (not black)',
    () async {
      final GarakeFilterEngineImpl engine = GarakeFilterEngineImpl();
      final img.Image source = img.Image(width: 100, height: 80);

      // Fill with a mid-tone color
      for (int y = 0; y < source.height; y++) {
        for (int x = 0; x < source.width; x++) {
          source.setPixelRgba(x, y, 128, 128, 128, 255);
        }
      }

      final Uint8List input = Uint8List.fromList(
        img.encodeJpg(source, quality: 95),
      );
      final Uint8List output = await engine.applyGarakeFilter(
        input,
        FilterConfig.v1,
        DateTime(2026, 2, 22),
      );

      final img.Image? decoded = img.decodeImage(output);
      expect(decoded, isNotNull);

      // Compute average brightness across all pixels
      double totalBrightness = 0;
      for (int y = 0; y < decoded!.height; y++) {
        for (int x = 0; x < decoded.width; x++) {
          final img.Pixel p = decoded.getPixel(x, y);
          totalBrightness += (0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b);
        }
      }
      final double avgBrightness =
          totalBrightness / (decoded.width * decoded.height);

      // A mid-tone input should produce average brightness well above 20
      expect(
        avgBrightness,
        greaterThan(40),
        reason:
            'Filtered image should not be nearly black. Got avg brightness: $avgBrightness',
      );
    },
  );
}
