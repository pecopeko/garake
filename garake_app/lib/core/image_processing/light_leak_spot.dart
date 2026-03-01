// Holds precomputed parameters for one procedural light leak blob.
/*
Dependency Memo
- Depends on: Dart core types only.
- Requires methods: none.
- Provides methods: _LeakSpot data carrier.
*/
class LeakSpot {
  const LeakSpot({
    required this.cx,
    required this.cy,
    required this.sigma,
    required this.r,
    required this.g,
    required this.b,
    required this.strength,
  });

  final double cx;
  final double cy;
  final double sigma;
  final double r;
  final double g;
  final double b;
  final double strength;
}
