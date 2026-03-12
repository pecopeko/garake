// Figmaノード46:5の閉じたガラケー本体。筐体・ヒンジ・サブディスプレイを描画する。
/*
Dependency Memo
- Depends on: garake_home_screen.dart の親プロパティと _HomeDisplayPanel / _HomeSideKey / _HomeCenterKey 部品。
- Requires methods: onCameraTap(), onGalleryTap() でホーム操作を通知する。
- Provides methods: _HomePhoneBody.build().
*/
part of 'garake_home_screen.dart';

class _HomePhoneBody extends StatelessWidget {
  const _HomePhoneBody({
    required this.scale,
    required this.timeText,
    required this.dateText,
    required this.selectedIndex,
    required this.cameraLabel,
    required this.galleryLabel,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final double scale;
  final String timeText;
  final String dateText;
  final int selectedIndex;
  final String cameraLabel;
  final String galleryLabel;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    final int safeIndex = selectedIndex < 0
        ? 0
        : (selectedIndex > 1 ? 1 : selectedIndex);
    final VoidCallback selectedAction = safeIndex == 0
        ? onCameraTap
        : onGalleryTap;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: _s(313.684),
            height: _s(596),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_s(36)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFFDB7C1),
                  Color(0xFFFF85A1),
                  Color(0xFFFF69B4),
                  Color(0xFFE8507A),
                ],
                stops: <double>[0.10, 0.34, 0.58, 0.89],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0x59000000),
                  blurRadius: _s(80),
                  offset: Offset(0, _s(20)),
                ),
                BoxShadow(
                  color: const Color(0x66DC5078),
                  blurRadius: _s(32),
                  offset: Offset(0, _s(8)),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: _s(25.09),
                  top: _s(12.55),
                  child: Container(
                    width: _s(263.495),
                    height: _s(125.474),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_s(28)),
                        topRight: Radius.circular(_s(28)),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0x8CFFFFFF), Color(0x1AFFFFFF)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: _s(290.16),
                  child: Container(
                    width: _s(313.684),
                    height: _s(15.684),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0x2E000000),
                          Color(0x0D000000),
                          Color(0x33FFFFFF),
                          Color(0x1F000000),
                        ],
                        stops: <double>[0.0, 0.4, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _s(15.68),
                  top: _s(285.45),
                  child: _HingeCap(scale: scale),
                ),
                Positioned(
                  left: _s(266.63),
                  top: _s(285.45),
                  child: _HingeCap(scale: scale),
                ),
                Positioned(
                  left: _s(121.55),
                  top: _s(28.23),
                  child: Row(
                    children: List<Widget>.generate(7, (int index) {
                      return Container(
                        width: _s(index == 6 ? 8.4 : 4.705),
                        height: _s(4.705),
                        margin: EdgeInsets.only(
                          right: index == 6 ? 0 : _s(6.274),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x40000000),
                          borderRadius: BorderRadius.circular(_s(1.5)),
                        ),
                      );
                    }),
                  ),
                ),
                Positioned(
                  left: _s(86.26),
                  top: _s(51.76),
                  child: _HomeDisplayPanel(
                    scale: scale,
                    timeText: timeText,
                    dateText: dateText,
                  ),
                ),
                Positioned(
                  left: _s(142.73),
                  top: _s(183.51),
                  child: _HomeCenterKey(
                    scale: scale,
                    isActive: true,
                    onTap: selectedAction,
                    semanticLabel: safeIndex == 0 ? cameraLabel : galleryLabel,
                  ),
                ),
                Positioned(
                  left: _s(120.13),
                  top: _s(512.87),
                  child: _HomeBrandMark(scale: scale),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_s(36)),
                        border: Border.all(
                          color: const Color(0x1FFFFFFF),
                          width: _s(1.1),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x14FFFFFF),
                            Color(0x00FFFFFF),
                            Color(0x1F000000),
                          ],
                          stops: <double>[0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: _s(310.55),
          top: _s(178.8),
          child: _HomeSideKey(
            scale: scale,
            isActive: safeIndex == 0,
            semanticLabel: cameraLabel,
            onTap: onCameraTap,
          ),
        ),
        Positioned(
          left: _s(310.55),
          top: _s(235.26),
          child: _HomeSideKey(
            scale: scale,
            isActive: safeIndex == 1,
            semanticLabel: galleryLabel,
            onTap: onGalleryTap,
          ),
        ),
        Positioned(
          left: _s(-6.27),
          top: _s(25.09),
          child: _HomeStrapAnchor(scale: scale),
        ),
      ],
    );
  }
}

class _HingeCap extends StatelessWidget {
  const _HingeCap({required this.scale});

  final double scale;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _s(31.368),
      height: _s(25.095),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_s(6)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFE8507A),
            Color(0xFFC0305A),
            Color(0xFFE8507A),
          ],
          stops: <double>[0.0, 0.5, 1.0],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0x4D000000),
            blurRadius: _s(4),
            offset: Offset(0, _s(2)),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_s(6)),
          border: Border.all(color: const Color(0x4DFFFFFF), width: _s(0.8)),
        ),
      ),
    );
  }
}

class _HomeBrandMark extends StatelessWidget {
  const _HomeBrandMark({required this.scale});

  final double scale;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextStyle heartStyle = TextStyle(
      color: const Color(0xB3FFFFFF),
      fontSize: _s(10),
      letterSpacing: _s(0.12),
      height: 1,
    );

    return SizedBox(
      width: _s(73.409),
      height: _s(51.758),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: _s(23.526),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('♡', style: heartStyle),
                SizedBox(width: _s(18)),
                Text('♡', style: heartStyle),
                SizedBox(width: _s(18)),
                Text('♡', style: heartStyle),
              ],
            ),
          ),
          SizedBox(height: _s(9.4)),
          SizedBox(
            width: _s(94),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n.brandWordmark,
                style: TextStyle(
                  color: const Color(0x80FFFFFF),
                  fontSize: _s(8),
                  letterSpacing: _s(l10n.isJapanese ? 3 : 1.1),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
