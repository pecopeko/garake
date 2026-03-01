// Holds fixed filter tuning values for the Garake visual profile.
/*
Dependency Memo
- Depends on: Dart core types only.
- Requires methods: none.
- Provides methods: FilterConfig.v1 preset.
*/
class FilterConfig {
  const FilterConfig({
    required this.downscaleShortSide,
    required this.jpegQuality,
    required this.shadowLift,
    required this.highlightCompression,
    required this.toneContrast,
    required this.whiteBalanceWarmth,
    required this.shadowCyanCast,
    required this.shadowGreenCast,
    required this.highlightWarmCast,
    required this.softenSigma,
    required this.softenMix,
    required this.grainFineStrength,
    required this.grainCoarseStrength,
    required this.grainFineScale,
    required this.grainCoarseScale,
    required this.vignetteStrength,
    required this.edgeDesaturation,
    required this.edgeHueShift,
    required this.halationThreshold,
    required this.halationStrength,
    required this.lightLeakChance,
    required this.lightLeakStrength,
    required this.chromaShift,
    required this.dateStampJitter,
    required this.dateStampBlur,
    required this.dateStampRgbSplit,
  });

  final int downscaleShortSide;
  final int jpegQuality;

  final double shadowLift;
  final double highlightCompression;
  final double toneContrast;

  final double whiteBalanceWarmth;
  final double shadowCyanCast;
  final double shadowGreenCast;
  final double highlightWarmCast;

  final double softenSigma;
  final double softenMix;

  final double grainFineStrength;
  final double grainCoarseStrength;
  final double grainFineScale;
  final double grainCoarseScale;

  final double vignetteStrength;
  final double edgeDesaturation;
  final double edgeHueShift;

  final double halationThreshold;
  final double halationStrength;

  final double lightLeakChance;
  final double lightLeakStrength;

  final int chromaShift;

  final int dateStampJitter;
  final double dateStampBlur;
  final double dateStampRgbSplit;

  static const FilterConfig v1 = FilterConfig(
    downscaleShortSide: 1080,
    jpegQuality: 84,
    shadowLift: 0.08,
    highlightCompression: 0.10,
    toneContrast: 0.08,
    whiteBalanceWarmth: 0.10,
    shadowCyanCast: 0.08,
    shadowGreenCast: 0.06,
    highlightWarmCast: 0.10,
    softenSigma: 0.55,
    softenMix: 0.10,
    grainFineStrength: 0.065,
    grainCoarseStrength: 0.05,
    grainFineScale: 0.55,
    grainCoarseScale: 1.15,
    vignetteStrength: 0.22,
    edgeDesaturation: 0.12,
    edgeHueShift: 0.04,
    halationThreshold: 0.80,
    halationStrength: 0.08,
    lightLeakChance: 0.15,
    lightLeakStrength: 0.08,
    chromaShift: 0,
    dateStampJitter: 2,
    dateStampBlur: 0.65,
    dateStampRgbSplit: 0.6,
  );
}
