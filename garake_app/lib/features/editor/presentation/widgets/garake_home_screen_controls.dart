// Figmaノード46:5の補助部品。サブディスプレイと操作キーの見た目とタップ領域をまとめる。
/*
Dependency Memo
- Depends on: garake_home_screen.dart から共有される Material API とホーム画面用親データ。
- Requires methods: onTap() で各キー操作を親へ返す。
- Provides methods: _HomeDisplayPanel.build(), _HomeSideKey.build(), _HomeCenterKey.build(), _HomeStrapAnchor.build().
*/
part of 'garake_home_screen.dart';

class _HomeDisplayPanel extends StatelessWidget {
  const _HomeDisplayPanel({
    required this.scale,
    required this.timeText,
    required this.dateText,
  });

  final double scale;
  final String timeText;
  final String dateText;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _s(141.158),
      height: _s(109.789),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_s(8)),
        border: Border.all(color: const Color(0x66000000), width: _s(2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
          stops: <double>[0.15, 0.85],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0x4D000000),
            blurRadius: _s(4),
            offset: Offset(0, _s(2)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_s(6)),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.15, -0.85),
                    radius: 1.1,
                    colors: <Color>[
                      const Color(0x3DFFB4C6),
                      const Color(0x120A0616),
                      const Color(0x00000000),
                    ],
                    stops: const <double>[0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: _s(17.57),
              top: _s(8.5),
              child: Text(
                timeText,
                style: TextStyle(
                  color: const Color(0xFFFF85A1),
                  fontSize: _s(20),
                  letterSpacing: _s(1),
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              left: _s(10.55),
              top: _s(46.2),
              child: Opacity(
                opacity: 0.85,
                child: Text(
                  dateText,
                  style: TextStyle(
                    color: const Color(0xFFFF85A1),
                    fontSize: _s(9),
                    letterSpacing: _s(0.5),
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: _s(37.99),
              top: _s(88.97),
              child: SizedBox(
                width: _s(61.168),
                height: _s(15.684),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      width: _s(23.526),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          _SignalBar(scale: scale, height: 6.274),
                          SizedBox(width: _s(1.568)),
                          _SignalBar(scale: scale, height: 9.411),
                          SizedBox(width: _s(1.568)),
                          _SignalBar(scale: scale, height: 12.547),
                          SizedBox(width: _s(1.568)),
                          Container(
                            width: _s(4.705),
                            height: _s(15.684),
                            decoration: BoxDecoration(
                              color: const Color(0x4DFF85A1),
                              borderRadius: BorderRadius.circular(_s(1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: _s(25.095),
                      height: _s(12.547),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_s(2)),
                        border: Border.all(
                          color: const Color(0x99FF85A1),
                          width: _s(1),
                        ),
                      ),
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            left: _s(2.14),
                            top: _s(2.14),
                            child: Container(
                              width: _s(13.16),
                              height: _s(6.274),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF85A1),
                                borderRadius: BorderRadius.circular(_s(1)),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: const Color(0x99FF85A1),
                                    blurRadius: _s(3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: _s(-2.2),
                            top: _s(2.14),
                            child: Container(
                              width: _s(3.137),
                              height: _s(6.274),
                              decoration: BoxDecoration(
                                color: const Color(0x99FF85A1),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(_s(1)),
                                  bottomRight: Radius.circular(_s(1)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: _s(10.55),
              top: _s(5.84),
              child: Container(
                width: _s(116.063),
                height: _s(21.958),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_s(4)),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x1FFFFFFF), Color(0x00000000)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_s(6)),
                    border: Border.all(
                      color: const Color(0x22000000),
                      width: _s(1),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0x12000000),
                        Color(0x00000000),
                        Color(0x66000000),
                      ],
                      stops: <double>[0.0, 0.6, 1.0],
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

class _SignalBar extends StatelessWidget {
  const _SignalBar({required this.scale, required this.height});

  final double scale;
  final double height;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _s(4.705),
      height: _s(height),
      decoration: BoxDecoration(
        color: const Color(0xFFFF85A1),
        borderRadius: BorderRadius.circular(_s(1)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: const Color(0x99FF85A1), blurRadius: _s(3)),
        ],
      ),
    );
  }
}

class _HomeCenterKey extends StatelessWidget {
  const _HomeCenterKey({
    required this.scale,
    required this.isActive,
    required this.onTap,
    required this.semanticLabel,
  });

  final double scale;
  final bool isActive;
  final VoidCallback onTap;
  final String semanticLabel;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _s(28.232),
          height: _s(28.232),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_s(9)),
            border: Border.all(
              color: isActive
                  ? const Color(0x99000000)
                  : const Color(0x66000000),
              width: _s(2),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF2A2A3E),
                Color(0xFF0A0A14),
                Color(0xFF1A1A2E),
              ],
              stops: <double>[0.0, 0.6, 1.0],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0x80000000),
                blurRadius: _s(4),
                offset: Offset(0, _s(2)),
              ),
              if (isActive)
                BoxShadow(color: const Color(0x66FF85A1), blurRadius: _s(6)),
            ],
          ),
          child: Center(
            child: Container(
              width: _s(15.684),
              height: _s(15.684),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_s(5)),
                border: Border.all(
                  color: const Color(0x33FFFFFF),
                  width: _s(0.8),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF6F5D91), Color(0xFF39355F)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSideKey extends StatelessWidget {
  const _HomeSideKey({
    required this.scale,
    required this.isActive,
    required this.semanticLabel,
    required this.onTap,
  });

  final double scale;
  final bool isActive;
  final String semanticLabel;
  final VoidCallback onTap;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _s(9.411),
          height: _s(43.916),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(_s(4)),
              bottomRight: Radius.circular(_s(4)),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isActive
                  ? const <Color>[
                      Color(0xFFF16A93),
                      Color(0xFFC0305A),
                      Color(0xFFE8507A),
                    ]
                  : const <Color>[
                      Color(0xFFD85B82),
                      Color(0xFFAD2D52),
                      Color(0xFFD14C74),
                    ],
              stops: const <double>[0.0, 0.5, 1.0],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0x4D000000),
                blurRadius: _s(4),
                offset: Offset(_s(2), 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeStrapAnchor extends StatelessWidget {
  const _HomeStrapAnchor({required this.scale});

  final double scale;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _s(12.547),
      height: _s(15.684),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_s(4)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFC0305A), Color(0xFFA02040)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0x66000000),
            blurRadius: _s(2),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: _s(4.705),
          height: _s(7.842),
          decoration: BoxDecoration(
            color: const Color(0x99000000),
            borderRadius: BorderRadius.circular(_s(2)),
          ),
        ),
      ),
    );
  }
}
