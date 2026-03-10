// Figma参照のネオンホーム画面。時刻表示を残したまま4タイル導線へ置き換える。
/*
Dependency Memo
- Depends on: Flutter Material animation/widget APIs and app_theme.dart for shared accent colors.
- Requires methods: onCameraPressed() と onEditPhotoPressed() で既存導線を親へ返す。
- Provides methods: GarakeHomeDisplay.build().
*/
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class GarakeHomeDisplay extends StatefulWidget {
  const GarakeHomeDisplay({
    super.key,
    required this.selectedIndex,
    this.onCameraPressed,
    this.onEditPhotoPressed,
  });

  final int selectedIndex;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onEditPhotoPressed;

  @override
  State<GarakeHomeDisplay> createState() => _GarakeHomeDisplayState();
}

class _GarakeHomeDisplayState extends State<GarakeHomeDisplay>
    with SingleTickerProviderStateMixin {
  static const List<String> _weekdayLabels = <String>[
    '月',
    '火',
    '水',
    '木',
    '金',
    '土',
    '日',
  ];

  late final AnimationController _tickerController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String mainTime =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final String detailDate =
        "'${(_now.year % 100).toString().padLeft(2, '0')}.${_now.month.toString().padLeft(2, '0')}.${_now.day.toString().padLeft(2, '0')} (${_weekdayLabels[_now.weekday - 1]})";
    final int safeSelectedIndex = widget.selectedIndex < 0
        ? 0
        : (widget.selectedIndex > 1 ? 1 : widget.selectedIndex);
    final List<_HomeShortcutData> shortcuts = <_HomeShortcutData>[
      _HomeShortcutData(
        emoji: '📷',
        label: 'カメラ',
        description: 'しゃしんをとる',
        beginColor: const Color(0xFFFF58B7),
        endColor: const Color(0xFFFF1493),
        borderColor: const Color(0xFFFF8AD5),
        glowColor: const Color(0x73FF69B4),
        isSelected: safeSelectedIndex == 0,
        onTap: widget.onCameraPressed,
      ),
      _HomeShortcutData(
        emoji: '🖼️',
        label: 'アルバム',
        description: 'おもいでをみる',
        beginColor: const Color(0xFF9B73F2),
        endColor: const Color(0xFF6A0DAD),
        borderColor: const Color(0xFFC1A5FF),
        glowColor: const Color(0x739370DB),
        isSelected: safeSelectedIndex == 1,
        onTap: widget.onEditPhotoPressed,
      ),
      const _HomeShortcutData(
        emoji: '✨',
        label: 'デコる',
        description: 'かわいくデコ',
        beginColor: Color(0xFF14D5E3),
        endColor: Color(0xFF008B8B),
        borderColor: Color(0xFF68F2FF),
        glowColor: Color(0x7300CED1),
      ),
      const _HomeShortcutData(
        emoji: '🎀',
        label: '動画を撮る',
        description: 'どうがをとる',
        beginColor: Color(0xFFFFD400),
        endColor: Color(0xFFFF9800),
        borderColor: Color(0xFFFFEE6A),
        glowColor: Color(0x73FFD700),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF070011),
            Color(0xFF14002A),
            Color(0xFF090012),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            left: -22,
            top: 40,
            child: _BackdropGlow(
              width: 96,
              height: 96,
              colors: <Color>[Color(0x40FF6CC8), Color(0x00000000)],
            ),
          ),
          const Positioned(
            right: -30,
            top: 124,
            child: _BackdropGlow(
              width: 120,
              height: 120,
              colors: <Color>[Color(0x3600E7FF), Color(0x00000000)],
            ),
          ),
          const Positioned(
            left: 118,
            bottom: 14,
            child: _BackdropGlow(
              width: 132,
              height: 90,
              colors: <Color>[Color(0x29FFCC4D), Color(0x00000000)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _AnimatedTickerBar(
                  controller: _tickerController,
                  message: '💖 かわいい写真を撮ろう！ 💖',
                ),
                const SizedBox(height: 10),
                _HomeClockCard(
                  timeText: mainTime,
                  dateText: detailDate,
                  selectedIndex: safeSelectedIndex,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shortcuts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.96,
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      return _HomeShortcutTile(data: shortcuts[index]);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  safeSelectedIndex == 0
                      ? '↑↓でえらぶ / OKでカメラ'
                      : '↑↓でえらぶ / OKでアルバム',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xB3FBEF8F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 背景のネオンにじみを分離して、配色調整をしやすくする。
class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: colors, stops: const <double>[0, 1]),
        ),
      ),
    );
  }
}

// 上部のテロップを横移動させてガラケー風の遊びを足す。
class _AnimatedTickerBar extends StatelessWidget {
  const _AnimatedTickerBar({required this.controller, required this.message});

  final Animation<double> controller;
  final String message;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(
      color: Color(0xFFFFD75D),
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
      height: 1.15,
      shadows: <Shadow>[Shadow(color: Color(0x99FF6CB6), blurRadius: 4)],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: message, style: style),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();
        final double loopWidth = painter.width + 28;

        return Container(
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF22003F),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0x7AFF69B4)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: <Widget>[
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0x3DFFFFFF), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: controller,
                  builder: (BuildContext context, Widget? child) {
                    final double left = -(controller.value * loopWidth);
                    return Positioned(
                      left: left,
                      top: 1,
                      child: Row(
                        children: List<Widget>.generate(3, (int index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == 2 ? 0 : 28,
                            ),
                            child: Text(message, style: style),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 時刻と現在モードを小さなステータスカードへ集約する。
class _HomeClockCard extends StatelessWidget {
  const _HomeClockCard({
    required this.timeText,
    required this.dateText,
    required this.selectedIndex,
  });

  final String timeText;
  final String dateText;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final String statusLabel = selectedIndex == 0
        ? 'CAMERA READY'
        : 'ALBUM READY';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x40F8B7FF)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF130725), Color(0xFF090313)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'garake home',
                  style: TextStyle(
                    color: Color(0xFFFF94CE),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Color(0xFFD5C8FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0x33FF62B0),
                  border: Border.all(color: const Color(0x55FF62B0)),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Color(0xFFFEE46B),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '♥  ✦  ♥',
                style: TextStyle(
                  color: Color(0xFFFF90CB),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 46,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xAAFFF1A0), width: 1),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFFFFFFA0), Color(0xFFFFD400)],
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Color(0x55FFD400), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Figmaの4分割ボタンをベースに、既存導線の選択状態だけ追加する。
class _HomeShortcutTile extends StatelessWidget {
  const _HomeShortcutTile({required this.data});

  final _HomeShortcutData data;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = data.onTap != null;
    final double scale = data.isSelected ? 1.02 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: data.borderColor,
                width: data.isSelected ? 2.4 : 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[data.beginColor, data.endColor],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0x66000000),
                  blurRadius: data.isSelected ? 14 : 10,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: data.glowColor,
                  blurRadius: data.isSelected ? 16 : 10,
                ),
                if (data.isSelected)
                  BoxShadow(
                    color: AppTheme.pink.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 12,
                  right: 12,
                  top: 4,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0x47FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          data.emoji,
                          style: const TextStyle(fontSize: 32, height: 1.1),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: isInteractive ? 0.76 : 0.62,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isInteractive)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x29000000),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Text(
                        'soon',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// タイルの配色と動作を小さなデータへ閉じ込める。
class _HomeShortcutData {
  const _HomeShortcutData({
    required this.emoji,
    required this.label,
    required this.description,
    required this.beginColor,
    required this.endColor,
    required this.borderColor,
    required this.glowColor,
    this.isSelected = false,
    this.onTap,
  });

  final String emoji;
  final String label;
  final String description;
  final Color beginColor;
  final Color endColor;
  final Color borderColor;
  final Color glowColor;
  final bool isSelected;
  final VoidCallback? onTap;
}
