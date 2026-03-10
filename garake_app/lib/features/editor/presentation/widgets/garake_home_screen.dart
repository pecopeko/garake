// Figmaノード46:5準拠のホーム画面。閉じたガラケー本体デザインを全体表示する。
/*
Dependency Memo
- Depends on: Flutter Material widgets and split part files for phone rendering.
- Requires methods: onActionTap() for side-button action taps.
- Provides methods: GarakeHomeScreen.build().
*/
import 'package:flutter/material.dart';

part 'garake_home_screen_phone.dart';
part 'garake_home_screen_controls.dart';

class GarakeHomeScreen extends StatelessWidget {
  const GarakeHomeScreen({
    super.key,
    required this.actions,
    required this.selectedIndex,
    required this.onActionTap,
  });

  final List<GarakeHomeActionItem> actions;
  final int selectedIndex;
  final ValueChanged<int> onActionTap;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    const List<String> weekDays = <String>['月', '火', '水', '木', '金', '土', '日'];
    final String timeText =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final String dateText =
        "'${(now.year % 100).toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} (${weekDays[now.weekday - 1]})";

    return Container(
      key: const Key('editor-empty-canvas'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFD9DADF), Color(0xFFC8C9CF)],
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double figmaWidth = 320.0;
          const double figmaHeight = 596.0;
          final double widthBased = constraints.biggest.width / figmaWidth;
          final double heightBased = constraints.biggest.height / figmaHeight;
          final double fitScale =
              (widthBased < heightBased ? widthBased : heightBased)
                  .clamp(0.8, 1.7)
                  .toDouble();
          final String cameraLabel = actions.isNotEmpty
              ? actions.first.label
              : '写真を撮る';
          final String galleryLabel = actions.length > 1
              ? actions[1].label
              : '写真を編集する';

          return Center(
            child: SizedBox(
              width: figmaWidth * fitScale,
              height: figmaHeight * fitScale,
              child: _HomePhoneBody(
                scale: fitScale,
                timeText: timeText,
                dateText: dateText,
                selectedIndex: selectedIndex,
                cameraLabel: cameraLabel,
                galleryLabel: galleryLabel,
                onCameraTap: () => onActionTap(0),
                onGalleryTap: () => onActionTap(actions.length > 1 ? 1 : 0),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GarakeHomeActionItem {
  const GarakeHomeActionItem({required this.iconGlyph, required this.label});

  final String iconGlyph;
  final String label;
}
