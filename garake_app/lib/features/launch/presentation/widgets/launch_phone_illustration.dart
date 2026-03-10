// 起動画面で使う閉じたガラケー前面カバー。前面全体が下ヒンジから開く見え方を描画する。
/*
Dependency Memo
- Depends on: Flutter Material primitives and launch phone display widgets.
- Requires methods: LaunchSubDisplay constructor, LaunchTopSpeaker constructor.
- Provides methods: LaunchPhoneIllustration.build().
*/
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'launch_phone_display.dart';

class LaunchPhoneIllustration extends StatelessWidget {
  const LaunchPhoneIllustration({super.key, required this.openProgress});

  final double openProgress;

  @override
  Widget build(BuildContext context) {
    final double coverProgress = Curves.easeInOutCubicEmphasized.transform(
      openProgress.clamp(0, 1),
    );
    final double shadowBlur = lerpDouble(74, 20, coverProgress);
    final double coverLift = lerpDouble(0, -42, coverProgress);
    final double undersideOpacity = Interval(
      0.12,
      0.82,
      curve: Curves.easeOutCubic,
    ).transform(coverProgress);
    final bool showUnderside = undersideOpacity > 0.02;

    return SizedBox(
      width: 200,
      height: 380,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(38),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0x66000000),
                    blurRadius: shadowBlur,
                    spreadRadius: 2.5,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            height: 20,
            child: IgnorePointer(
              child: showUnderside ? const _CoverHingeShadow() : const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              // カバー全体が底面ヒンジを支点に持ち上がる見え方を優先する。
              offset: Offset(0, coverLift),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  if (showUnderside)
                    const Positioned.fill(child: _PhoneCoverUnderside()),
                  const Positioned.fill(child: _PhoneFrontCover()),
                  const Positioned(
                    left: 12,
                    right: 12,
                    bottom: -2,
                    child: _BottomHinge(),
                  ),
                  const Positioned(right: -2, top: 232, child: _SideButton()),
                  const Positioned(right: -2, top: 270, child: _SideButton()),
                  const Positioned(left: -4, top: 28, child: _LeftSwitch()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

class _PhoneFrontCover extends StatelessWidget {
  const _PhoneFrontCover();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(38),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          // 平成感のあるガビガビグラデーション（バンド感強め）
          gradient: LinearGradient(
            begin: Alignment(-0.5, -0.95),
            end: Alignment(0.5, 0.95),
            colors: <Color>[
              Color(0xFFFF9AB8),
              Color(0xFFE8688E),
              Color(0xFFFF85A1),
              Color(0xFFD44A72),
              Color(0xFFE8688E),
              Color(0xFFCC3D65),
            ],
            stops: <double>[0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: Stack(
          children: <Widget>[
            // ノイズグレイン（平成のプラスチック質感）
            Positioned.fill(
              child: CustomPaint(
                painter: _CoverGrainPainter(),
              ),
            ),
            // 控えめのハイライト（マットな質感）
            Positioned(
              left: 18,
              top: 14,
              child: Container(
                width: 164,
                height: 118,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x28FFFFFF), Color(0x04FFFFFF)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 18,
              height: 166,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: const Color(0x14FFFFFF),
                    width: 1.0,
                  ),
                ),
              ),
            ),
            const Positioned(left: 77.5, top: 28, child: LaunchTopSpeaker()),
            const Positioned(left: 55, top: 46, child: LaunchSubDisplay()),
            Positioned(
              left: 87,
              top: 140,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0x6F000000),
                    width: 2.4,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF2A2A3E),
                      Color(0xFF0A0A14),
                      Color(0xFF171726),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const RadialGradient(
                        radius: 1,
                        colors: <Color>[
                          Color(0xFF3A3A63),
                          Color(0xFF1A1A35),
                          Color(0xFF0A0A1E),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              top: 212,
              child: Container(
                height: 112,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x20FFFFFF), Color(0x03FFFFFF)],
                  ),
                  border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 18,
                      top: 18,
                      child: Container(
                        width: 74,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: const Color(0x20FFFFFF),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 40,
                      child: Container(
                        width: 50,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: const Color(0x14FFFFFF),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 60,
                      child: Container(
                        width: 94,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: const Color(0x10FFFFFF),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 80,
                      child: Container(
                        width: 62,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: const Color(0x0CFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 38,
              child: Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Text(
                    '♡ ♡ ♡',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: Opacity(
                  opacity: 0.42,
                  child: Text(
                    'GARAKE',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 平成ガラケーのプラスチック質感ノイズ
class _CoverGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rng = math.Random(77);
    final Paint paint = Paint();
    const double step = 3;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final int alpha = rng.nextInt(22);
        if (alpha > 8) {
          paint.color = rng.nextBool()
              ? Color.fromARGB(alpha, 0, 0, 0)
              : Color.fromARGB(alpha ~/ 2, 255, 255, 255);
          canvas.drawRect(Rect.fromLTWH(x, y, step, step), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhoneCoverUnderside extends StatelessWidget {
  const _PhoneCoverUnderside();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(38),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFFCE4EC),
              Color(0xFFF8B5C7),
              Color(0xFFE27A9A),
            ],
            stops: <double>[0, 0.42, 1],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 20,
              right: 20,
              top: 20,
              height: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x40FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 34,
              right: 34,
              bottom: 28,
              height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: const Color(0x18FFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomHinge extends StatelessWidget {
  const _BottomHinge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            left: 22,
            right: 22,
            bottom: 4,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFFFA8C6), Color(0xFFD64B7A)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _HingeCap(alignment: Alignment.centerLeft),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _HingeCap(alignment: Alignment.centerRight),
          ),
        ],
      ),
    );
  }
}

class _HingeCap extends StatelessWidget {
  const _HingeCap({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFF8FB0), Color(0xFFE14A7B)],
        ),
      ),
      child: Align(
        alignment: alignment,
        child: Container(
          width: 12,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: const Color(0x2AFFFFFF),
          ),
        ),
      ),
    );
  }
}

class _CoverHingeShadow extends StatelessWidget {
  const _CoverHingeShadow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 18,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFFA7C1), Color(0xFFE24B86)],
        ),
      ),
    );
  }
}

class _LeftSwitch extends StatelessWidget {
  const _LeftSwitch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFFBCD0), Color(0xFFE46B93)],
        ),
      ),
    );
  }
}
