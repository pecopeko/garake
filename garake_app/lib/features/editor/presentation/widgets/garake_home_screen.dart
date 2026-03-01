// ガラケーのホーム画面。時計・日付・アプリアイコンを表示。
/*
Dependency Memo
- Depends on: Flutter widgets, AppTheme colors.
- Requires methods: onCameraPressed(), onEditPhotoPressed() callbacks.
- Provides methods: GarakeHomeScreen.build().
*/
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// 写真未読み込み時に表示するガラケー風ホーム画面。
/// アプリアイコン（カメラ・写真を編集する）をタップで操作可能。
class GarakeHomeScreen extends StatelessWidget {
  const GarakeHomeScreen({
    super.key,
    this.onCameraPressed,
    this.onEditPhotoPressed,
  });

  final VoidCallback? onCameraPressed;
  final VoidCallback? onEditPhotoPressed;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final String dateStr =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    // 曜日ラベル
    const List<String> weekDays = <String>[
      '月', '火', '水', '木', '金', '土', '日',
    ];
    final String dayOfWeek = weekDays[now.weekday - 1];

    return Container(
      key: const Key('editor-empty-canvas'),
      color: const Color(0xFF0A0408),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double scale = constraints.maxWidth / 240;
          return Column(
            children: <Widget>[
              SizedBox(height: 8 * scale),
              // キャリア名
              Text(
                '✿ garake ✿',
                style: TextStyle(
                  fontSize: 9 * scale,
                  color: const Color(0xFF6A4055),
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 4 * scale),
              // 時計表示
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 36 * scale,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.pinkLight,
                  letterSpacing: 2.0,
                  height: 1.1,
                ),
              ),
              // 日付
              Text(
                '$dateStr ($dayOfWeek)',
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: const Color(0xFF8A5070),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12 * scale),
              // 区切り線
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: Container(
                  height: 1,
                  color: const Color(0xFF3A1A28),
                ),
              ),
              SizedBox(height: 16 * scale),
              // アプリアイコン 2つ（カメラ・写真を編集する）
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _AppIcon(
                        scale: scale,
                        icon: Icons.camera_alt,
                        label: 'カメラ',
                        onTap: onCameraPressed,
                      ),
                      SizedBox(width: 24 * scale),
                      _AppIcon(
                        scale: scale,
                        icon: Icons.photo_library,
                        label: '写真を編集',
                        onTap: onEditPhotoPressed,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// アプリアイコン。アイコン + ラベル付き。タップ可能。
class _AppIcon extends StatelessWidget {
  const _AppIcon({
    required this.scale,
    required this.icon,
    required this.label,
    this.onTap,
  });
  final double scale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 52 * scale,
              height: 52 * scale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14 * scale),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF4A1830), Color(0xFF2A0A18)],
                ),
                border: Border.all(
                  color: AppTheme.pink.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.pink.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 26 * scale,
                color: AppTheme.pinkLight.withValues(alpha: 0.9),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9 * scale,
                color: const Color(0xFF8A5070),
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
