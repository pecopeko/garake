// 起動画面の外側サブディスプレイと表示要素を描画する。
/*
Dependency Memo
- Depends on: Flutter Material text/layout widgets and DateTime.
- Requires methods: DateTime.now().
- Provides methods: LaunchTopSpeaker.build(), LaunchSubDisplay.build().
*/
import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';

class LaunchTopSpeaker extends StatelessWidget {
  const LaunchTopSpeaker({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(7, (int index) {
        return Container(
          margin: EdgeInsets.only(right: index == 6 ? 0 : 4),
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0x40000000),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }
}

class LaunchSubDisplay extends StatelessWidget {
  const LaunchSubDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final String timeText =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final String dateText = l10n.formatLaunchDate(now);
    final String weekText = l10n.formatLaunchWeekday(now);

    return Container(
      width: 90,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x66000000), width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: const Alignment(-0.96, -0.92),
            child: Text(
              timeText,
              style: const TextStyle(
                color: Color(0xFFFF85A1),
                fontSize: 20,
                letterSpacing: 1,
                fontFamily: 'monospace',
                height: 1.1,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-1, -0.03),
            child: Text(
              dateText,
              style: const TextStyle(
                color: Color(0xE6FF85A1),
                fontSize: 9,
                letterSpacing: 0.5,
                fontFamily: 'monospace',
                height: 1.2,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-1, 0.34),
            child: Text(
              weekText,
              style: const TextStyle(
                color: Color(0xE6FF85A1),
                fontSize: 9,
                letterSpacing: 0.5,
                fontFamily: 'monospace',
                height: 1.2,
              ),
            ),
          ),
          const Positioned(left: 17, bottom: 6, child: _SignalBars()),
          Positioned(
            right: 7,
            bottom: 7,
            child: Container(
              width: 16,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: const Color(0x99FF85A1), width: 1),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 8.4,
                  height: 4,
                  margin: const EdgeInsets.only(left: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    color: const Color(0xFFFF85A1),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 9,
            child: Container(
              width: 2,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(1),
                ),
                color: const Color(0x99FF85A1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars();

  @override
  Widget build(BuildContext context) {
    const List<double> heights = <double>[4, 6, 8, 10];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights
          .map((double height) {
            final bool muted = height == 10;
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.only(right: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: muted
                    ? const Color(0x4DFF85A1)
                    : const Color(0xFFFF85A1),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
