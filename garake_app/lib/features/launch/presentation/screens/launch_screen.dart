// 起動画面。閉じたガラケーが上にパカッと開いてホームへ直接遷移する演出。
/*
Dependency Memo
- Depends on: launch phone illustration widget, Flutter animation APIs.
- Requires methods: LaunchPhoneIllustration constructor, Navigator.pushReplacement().
- Provides methods: LaunchScreen.build().
*/
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/launch_phone_illustration.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key, required this.nextRouteBuilder});

  final Route<void> Function() nextRouteBuilder;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _openController;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isOpening) {
      return;
    }
    setState(() {
      _isOpening = true;
    });
    await _openController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(widget.nextRouteBuilder());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Size viewport = constraints.biggest;
            return AnimatedBuilder(
              animation: _openController,
              builder: (BuildContext context, Widget? child) {
                final double t = _openController.value;

                // 一つの滑らかなカーブで全体を駆動
                final double smooth = Curves.easeInOutCubicEmphasized
                    .transform(t.clamp(0.0, 1.0));

                // カバー開き (0→~0.85 の範囲で完了)
                final double lidOpen =
                    Curves.easeOutCubic.transform((t / 0.85).clamp(0.0, 1.0));
                // 本体出現 (0.05→0.9, カバーとほぼ同時に動き出す)
                final double bodyT =
                    ((t - 0.05) / 0.85).clamp(0.0, 1.0);
                final double bodyReveal =
                    Curves.easeOutCubic.transform(bodyT);
                // フェードアウト (0.88→1.0)
                final double fadeOut =
                    Curves.easeInQuad.transform(((t - 0.88) / 0.12).clamp(0.0, 1.0));

                // サイズ定義
                const double phoneW = 200.0;
                const double phoneH = 380.0;
                // 開いた状態の本体全体（画面＋キーパッド）の高さ
                const double bodyH = phoneH * 0.85;

                final double cx = (viewport.width - phoneW) / 2;
                final double cy = (viewport.height - phoneH) / 2;

                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // 黒背景
                    const ColoredBox(color: Color(0xFF0A0A0E)),
                    // スキャンライン
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ScanLinePainter(),
                        ),
                      ),
                    ),
                    // ノイズグレイン
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _NoiseGrainPainter(),
                        ),
                      ),
                    ),
                    // 平成キラキラ装飾
                    ..._buildSparkles(viewport, 1.0 - fadeOut),
                    // 本体（画面＋キーパッド）がカバーの下からスムーズに出現
                    Positioned(
                      left: cx,
                      top: cy + phoneH - 16,
                      child: Opacity(
                        opacity: bodyReveal * (1.0 - fadeOut),
                        child: Transform.translate(
                          offset: Offset(0, _lerp(20, 0, bodyReveal)),
                          child: SizedBox(
                            width: phoneW,
                            height: bodyH,
                            child: const _OpenedBodyPreview(),
                          ),
                        ),
                      ),
                    ),
                    // カバーがヒンジ（底面中央）を支点に上に開く（開いたらすぐ消える）
                    if (lidOpen < 0.99)
                      Positioned(
                        left: cx,
                        top: cy,
                        child: Opacity(
                          opacity: (1.0 - lidOpen * 1.6).clamp(0.0, 1.0),
                          child: SizedBox(
                            width: phoneW,
                            height: phoneH,
                            child: Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0015)
                                ..rotateX(-lidOpen * (math.pi * 0.55)),
                              child: LaunchPhoneIllustration(
                                openProgress: lidOpen,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// 平成風キラキラ装飾を散りばめる
  static List<Widget> _buildSparkles(Size viewport, double opacity) {
    if (opacity < 0.01) {
      return const <Widget>[];
    }
    // 固定位置のキラキラ
    const List<_SparkleData> sparkles = <_SparkleData>[
      _SparkleData(0.12, 0.15, '✧', 14, 0.7),
      _SparkleData(0.85, 0.12, '✦', 10, 0.5),
      _SparkleData(0.08, 0.55, '☆', 12, 0.4),
      _SparkleData(0.92, 0.48, '✧', 16, 0.6),
      _SparkleData(0.15, 0.82, '✦', 11, 0.35),
      _SparkleData(0.88, 0.78, '☆', 9, 0.45),
      _SparkleData(0.5, 0.06, '✧', 13, 0.55),
      _SparkleData(0.35, 0.92, '✦', 10, 0.3),
      _SparkleData(0.72, 0.88, '✧', 8, 0.4),
      _SparkleData(0.2, 0.35, '・', 8, 0.5),
      _SparkleData(0.78, 0.3, '・', 6, 0.4),
      _SparkleData(0.65, 0.65, '・', 7, 0.35),
    ];

    return sparkles.map((_SparkleData s) {
      return Positioned(
        left: viewport.width * s.x,
        top: viewport.height * s.y,
        child: IgnorePointer(
          child: Opacity(
            opacity: s.opacity * opacity,
            child: Text(
              s.glyph,
              style: TextStyle(
                fontSize: s.size,
                color: const Color(0xFFFFD4E8),
                shadows: const <Shadow>[
                  Shadow(
                    color: Color(0x88FFFFFF),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(growable: false);
  }
}

class _SparkleData {
  const _SparkleData(this.x, this.y, this.glyph, this.size, this.opacity);

  final double x;
  final double y;
  final String glyph;
  final double size;
  final double opacity;
}

/// 平成ガビガビ感のスキャンライン（横縞）— 薄め
class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ピクセル感のあるノイズグレイン — 控えめ
class _NoiseGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rng = math.Random(42);
    final Paint paint = Paint();
    const double step = 5;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final int alpha = rng.nextInt(12);
        if (alpha > 5) {
          paint.color = Color.fromARGB(alpha, 255, 255, 255);
          canvas.drawRect(Rect.fromLTWH(x, y, step, step), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
/// 起動演出で開いたガラケーの本体プレビュー。
/// 上部＝画面エリア（暗いスクリーン＋ステータスバー風）、下部＝キーパッドエリア。
class _OpenedBodyPreview extends StatelessWidget {
  const _OpenedBodyPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF5C0D8),
              Color(0xFFF0A8C8),
              Color(0xFFE890B8),
              Color(0xFFF0A8C8),
              Color(0xFFF5C0D8),
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            // 上部：ディスプレイエリア
            Expanded(
              flex: 65,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF1A1A1A), Color(0xFF232323)],
                    ),
                    border: Border.all(
                      color: const Color(0xFF2F2F2F),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: const Color(0xFF050510),
                      border: Border.all(
                        color: const Color(0xFF161820),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        // ステータスバー
                        Container(
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          color: const Color(0xFF111111),
                          child: Row(
                            children: <Widget>[
                              const Text(
                                'Y!',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                              const SizedBox(width: 3),
                              // シグナルバー
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List<Widget>.generate(4, (int i) {
                                  return Container(
                                    width: 2,
                                    height: (3.0 + i * 1.5),
                                    margin: const EdgeInsets.only(right: 1),
                                    color: const Color(0xFF90D090),
                                  );
                                }),
                              ),
                              const Spacer(),
                              // バッテリー
                              Container(
                                width: 14,
                                height: 7,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF90D090),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 8,
                                  height: 4,
                                  margin: const EdgeInsets.only(left: 1),
                                  color: const Color(0xFF90D090),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // メイン画面エリア（黒い画面）
                        const Expanded(
                          child: ColoredBox(color: Color(0xFF0A0A12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 下部：キーパッドエリア
            Expanded(
              flex: 35,
              child: _KeypadArea(),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadArea extends StatelessWidget {
  const _KeypadArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF8D8E8),
            Color(0xFFF0C0D5),
            Color(0xFFE8B0C8),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: <Widget>[
          // モード切替キー
          Center(
            child: _pkey(48, 14, const Color(0xFFF0D0E0),
                border: const Color(0xFFC898B0)),
          ),
          const SizedBox(height: 6),
          // 中段：D-pad + サイドキー
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _pkey(32, 20, const Color(0xFFD0D0D0)),
                const SizedBox(width: 5),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _pkey(28, 12, const Color(0xFFF0E0E8)),
                      const SizedBox(height: 2),
                      Container(
                        width: 28,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0xFFFFFFFF),
                              Color(0xFFE0C8D5),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFA08098),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Color(0xFF503040),
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _pkey(28, 12, const Color(0xFFF0E0E8)),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                _pkey(32, 20, const Color(0xFFD0D0D0)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 下段：4つのソフトキー
          Row(
            children: <Widget>[
              Expanded(child: _pkey(double.infinity, 18, const Color(0xFFF8F0F4))),
              const SizedBox(width: 3),
              Expanded(child: _pkey(double.infinity, 18, const Color(0xFFF8F0F4))),
              const SizedBox(width: 3),
              Expanded(child: _pkey(double.infinity, 18, const Color(0xFFF8F0F4))),
              const SizedBox(width: 3),
              Expanded(child: _pkey(double.infinity, 18, const Color(0xFFF8F0F4))),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _pkey(double w, double h, Color color, {Color? border}) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: color,
        border: Border.all(
          color: border ?? const Color(0xFFB098A8),
          width: 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}


