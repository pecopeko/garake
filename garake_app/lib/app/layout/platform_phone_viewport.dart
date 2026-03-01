// Web表示をスマホ幅に揃えて、ネイティブと同じUI比率で確認しやすくする共通ラッパー。
/*
Dependency Memo
- Depends on: Flutter foundation/material for kIsWeb and layout primitives.
- Requires methods: LayoutBuilder(), MediaQuery.of().
- Provides methods: PlatformPhoneViewport.build().
*/
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformPhoneViewport extends StatelessWidget {
  const PlatformPhoneViewport({
    super.key,
    required this.child,
    this.webBreakpoint = 700,
    this.maxPhoneWidth = 430,
    this.minPhoneWidth = 320,
    this.phoneAspectRatio = 9 / 19.5,
    this.desktopBackground = const Color(0xFF12070D),
  });

  final Widget child;
  final double webBreakpoint;
  final double maxPhoneWidth;
  final double minPhoneWidth;
  final double phoneAspectRatio;
  final Color desktopBackground;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size viewport = constraints.biggest;
        final bool usePhoneFrame = viewport.width >= webBreakpoint;

        if (!usePhoneFrame) {
          return child;
        }

        final double widthFromViewport = viewport.width
            .clamp(minPhoneWidth, maxPhoneWidth)
            .toDouble();
        final double widthFromHeight = viewport.height * phoneAspectRatio;
        final double frameWidth = math.min(widthFromViewport, widthFromHeight);
        final double frameHeight = frameWidth / phoneAspectRatio;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: desktopBackground,
            gradient: const RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.0,
              colors: <Color>[Color(0xFF28111D), Color(0xFF12070D)],
            ),
          ),
          child: Center(
            child: Container(
              width: frameWidth,
              height: frameHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF7A465B).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x8A000000),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(size: Size(frameWidth, frameHeight)),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
