// ホーム待機画面の中身だけを描画し、外側シェルのステータスバーと二重表示しないようにする。
/*
Dependency Memo
- Depends on: Flutter Material widget APIs and app_theme.dart for shared pink accents.
- Requires methods: onCameraPressed(), onVideoPressed(), and onEditPhotoPressed() で親が遷移処理を受け取る。
- Provides methods: GarakeHomeDisplay.build().
*/
import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';

class GarakeHomeDisplay extends StatelessWidget {
  const GarakeHomeDisplay({
    super.key,
    required this.selectedIndex,
    this.onCameraPressed,
    this.onVideoPressed,
    this.onEditPhotoPressed,
  });

  final int selectedIndex;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onVideoPressed;
  final VoidCallback? onEditPhotoPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final String mainTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final String detailDate = l10n.formatHomeDate(now);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF1A1A1A),
            Color(0xFF222222),
            Color(0xFF1A1A1A),
          ],
          stops: <double>[0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x26FFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: _HomeScreenGlow()),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.homeBrandBanner,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      letterSpacing: l10n.isJapanese ? 3 : 1.1,
                      color: const Color(0xFFFF80A0),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mainTime,
                  style: const TextStyle(
                    fontSize: 52,
                    height: 1,
                    letterSpacing: 4,
                    color: Color(0xFFFFB8D0),
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detailDate,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF908090),
                  ),
                ),
                const SizedBox(height: 12),
                const _HeartDivider(),
                const SizedBox(height: 16),
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _HomeActionCard(
                        emoji: '📷',
                        label: l10n.homeTakePhoto,
                        isSelected: selectedIndex == 0,
                        onPressed: onCameraPressed,
                      ),
                      const SizedBox(width: 18),
                      _HomeActionCard(
                        emoji: '🎥',
                        label: l10n.homeTakeVideo,
                        isSelected: selectedIndex == 1,
                        onPressed: onVideoPressed,
                      ),
                      const SizedBox(width: 18),
                      _HomeActionCard(
                        emoji: '🖼',
                        label: l10n.homeEditPhoto,
                        isSelected: selectedIndex == 2,
                        onPressed: onEditPhotoPressed,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  '✧   ♥   ✧',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1.6,
                    color: Color(0xFFFF6090),
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

// 液晶の中心へうっすらピンク光を重ねてFigmaのにじみを再現する。
class _HomeScreenGlow extends StatelessWidget {
  const _HomeScreenGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.25),
            radius: 0.95,
            colors: <Color>[
              AppTheme.pink.withValues(alpha: 0.05),
              const Color(0x00000000),
            ],
          ),
        ),
      ),
    );
  }
}

// 中央ハート付きの水平ライン。ホーム画面の上下余白を締める。
class _HeartDivider extends StatelessWidget {
  const _HeartDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: Divider(height: 1, thickness: 1, color: Color(0xFF302028)),
        ),
        SizedBox(width: 4),
        Text(
          '♥',
          style: TextStyle(fontSize: 8, color: Color(0xFFFF6090), height: 1.5),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Divider(height: 1, thickness: 1, color: Color(0xFF302028)),
        ),
      ],
    );
  }
}

// 選択中の入力導線。液晶内タップは無効にしてキー操作だけを受ける。
class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.emoji,
    required this.label,
    required this.isSelected,
    this.onPressed,
  });

  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? const Color(0xFF6A2A48)
        : const Color(0xFF402030);
    final List<BoxShadow> shadows = <BoxShadow>[
      BoxShadow(
        color: const Color(0x26FF508C),
        blurRadius: isSelected ? 10 : 8,
      ),
    ];

    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF1A0810), Color(0xFF100008)],
                  ),
                  boxShadow: shadows,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 26,
                      color: isSelected
                          ? const Color(0xFFFFD9E4)
                          : const Color(0xFF0A0A0A),
                      shadows: isSelected
                          ? const <Shadow>[
                              Shadow(color: Color(0x26FF90B5), blurRadius: 10),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.3,
              color: isSelected
                  ? const Color(0xFFFFB8D0)
                  : const Color(0xFFB098A8),
            ),
          ),
        ],
      ),
    );
  }
}
