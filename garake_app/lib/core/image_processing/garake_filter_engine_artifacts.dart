// Holds artifact generators shared by the Garake filter, including leaks, chroma shift, and date stamp.
/*
Dependency Memo
- Depends on: garake_filter_engine_impl.dart library imports, light_leak_spot.dart, and intl for timestamp text.
- Requires methods: image draw/blur/composite APIs and helper math functions from the main filter library.
- Provides methods: _applyLightLeak(), _applyChromaShift(), _drawDateStamp(), _sigmaToRadius(), _clamp8(), _screen(), _smoothStep().
*/
part of 'garake_filter_engine_impl.dart';

void _applyLightLeak(img.Image image, FilterConfig config, int seed) {
  if (config.lightLeakStrength <= 0) {
    return;
  }

  final Random random = Random(seed);
  if (random.nextDouble() > config.lightLeakChance) {
    return;
  }

  final int leakCount = random.nextBool() ? 1 : 2;
  final int longSide = max(image.width, image.height);
  final double baseSigma = longSide * (0.10 + random.nextDouble() * 0.07);

  final List<LeakSpot> spots = <LeakSpot>[];
  for (int i = 0; i < leakCount; i++) {
    final int side = random.nextInt(4);
    final double cx;
    final double cy;
    if (side == 0) {
      cx = -image.width * 0.15;
      cy = random.nextDouble() * image.height;
    } else if (side == 1) {
      cx = image.width * 1.15;
      cy = random.nextDouble() * image.height;
    } else if (side == 2) {
      cx = random.nextDouble() * image.width;
      cy = -image.height * 0.15;
    } else {
      cx = random.nextDouble() * image.width;
      cy = image.height * 1.15;
    }

    final double tint = random.nextDouble();
    final double r = tint < 0.5 ? 1.0 : 0.98;
    final double g = tint < 0.5 ? 0.66 : 0.84;
    final double b = tint < 0.5 ? 0.40 : 0.56;
    final double strength =
        config.lightLeakStrength * (0.65 + random.nextDouble() * 0.55);

    spots.add(
      LeakSpot(
        cx: cx,
        cy: cy,
        sigma: baseSigma * (0.85 + random.nextDouble() * 0.3),
        r: r,
        g: g,
        b: b,
        strength: strength,
      ),
    );
  }

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final img.Pixel p = image.getPixel(x, y);
      double r = p.r / 255.0;
      double g = p.g / 255.0;
      double b = p.b / 255.0;

      for (final LeakSpot spot in spots) {
        final double dx = x - spot.cx;
        final double dy = y - spot.cy;
        final double d2 = dx * dx + dy * dy;
        final double falloff = exp(-d2 / (2 * spot.sigma * spot.sigma));
        final double k = (falloff * spot.strength).clamp(0.0, 1.0);
        if (k <= 0.001) {
          continue;
        }

        r = _screen(r, spot.r * k);
        g = _screen(g, spot.g * k);
        b = _screen(b, spot.b * k);
      }

      image.setPixelRgba(
        x,
        y,
        _clamp8(r * 255),
        _clamp8(g * 255),
        _clamp8(b * 255),
        p.a,
      );
    }
  }
}

img.Image _applyChromaShift(img.Image image, int shift) {
  if (shift <= 0) {
    return image;
  }

  final img.Image source = img.Image.from(image);
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final int rx = (x - shift).clamp(0, image.width - 1);
      final int bx = (x + shift).clamp(0, image.width - 1);
      final img.Pixel current = image.getPixel(x, y);
      final img.Pixel redShifted = source.getPixel(rx, y);
      final img.Pixel blueShifted = source.getPixel(bx, y);
      image.setPixelRgba(
        x,
        y,
        redShifted.r,
        current.g,
        blueShifted.b,
        current.a,
      );
    }
  }
  return image;
}

void _drawDateStamp(img.Image image, DateTime now, FilterConfig config) {
  final String date = DateFormat('yy.MM.dd').format(now);
  final int textWidth = date.length * 14;
  final int baseX = max(8, image.width - textWidth - 10);
  final int baseY = max(8, image.height - 34);
  final Random random = Random(
    now.microsecondsSinceEpoch ^ image.width ^ image.height,
  );

  final int jitter = config.dateStampJitter;
  final int jitterX = random.nextInt(jitter * 2 + 1) - jitter;
  final int jitterY = random.nextInt(jitter * 2 + 1) - jitter;
  final double rgbSplit = config.dateStampRgbSplit.clamp(0.0, 2.0);

  final img.Image stampLayer = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 4,
  );
  img.drawString(
    stampLayer,
    date,
    font: img.arial24,
    x: baseX + jitterX,
    y: baseY + jitterY,
    color: img.ColorRgba8(238, 225, 116, 208),
  );
  img.drawString(
    stampLayer,
    date,
    font: img.arial24,
    x: baseX + jitterX - rgbSplit.round(),
    y: baseY + jitterY,
    color: img.ColorRgba8(255, 123, 100, 84),
  );
  img.drawString(
    stampLayer,
    date,
    font: img.arial24,
    x: baseX + jitterX + rgbSplit.round(),
    y: baseY + jitterY + 1,
    color: img.ColorRgba8(184, 255, 226, 70),
  );

  final int blurRadius = _sigmaToRadius(config.dateStampBlur);
  if (blurRadius > 0) {
    img.gaussianBlur(stampLayer, radius: blurRadius);
  }

  _addStampTexture(
    stampLayer,
    baseX + jitterX,
    baseY + jitterY,
    textWidth,
    random,
  );
  img.compositeImage(image, stampLayer);
}

void _addStampTexture(
  img.Image layer,
  int x,
  int y,
  int textWidth,
  Random random,
) {
  final int x0 = max(0, x - 3);
  final int y0 = max(0, y - 3);
  final int x1 = min(layer.width - 1, x + textWidth + 3);
  final int y1 = min(layer.height - 1, y + 30);

  for (int py = y0; py <= y1; py++) {
    for (int px = x0; px <= x1; px++) {
      final img.Pixel p = layer.getPixel(px, py);
      if (p.a <= 0) {
        continue;
      }
      final int drift = random.nextInt(17) - 8;
      layer.setPixelRgba(
        px,
        py,
        _clamp8(p.r + drift),
        _clamp8(p.g + drift),
        _clamp8(p.b + drift),
        p.a,
      );
    }
  }
}

int _sigmaToRadius(double sigma) {
  if (sigma <= 0) {
    return 0;
  }
  return max(1, (sigma * 1.8).round());
}

int _clamp8(num value) => value.round().clamp(0, 255);

double _screen(double base, double blend) {
  final double b = base.clamp(0.0, 1.0);
  final double l = blend.clamp(0.0, 1.0);
  return 1.0 - (1.0 - b) * (1.0 - l);
}

double _smoothStep(double edge0, double edge1, double x) {
  final double t = ((x - edge0) / max(0.0001, edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}
