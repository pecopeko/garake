// カワイイ風全画面ガラケーシェル。IMG_2195のレイアウト + framework.JPGの装飾。
/*
Dependency Memo
- Depends on: Flutter Material/Services, caller-provided preview/menu widgets, keypad callbacks, AppTheme colors.
- Requires methods: onMenuPressed(), onStampPressed(), onSaveSharePressed(), onUpPressed(), onDownPressed(), onLeftPressed(), onRightPressed(), onOkPressed(), HapticFeedback.selectionClick().
- Provides methods: GarakeShell.build().
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';

part 'garake_shell_layout.dart';
part 'garake_shell_keypad.dart';

void _triggerKeyPress(VoidCallback action) {
  HapticFeedback.selectionClick();
  action();
}

class GarakeShell extends StatelessWidget {
  const GarakeShell({
    super.key,
    required this.preview,
    required this.isBusy,
    required this.photoLoaded,
    required this.modeLabel,
    required this.selectionLabel,
    required this.onMenuPressed,
    required this.onStampPressed,
    required this.onSaveSharePressed,
    required this.onUpPressed,
    required this.onDownPressed,
    required this.onLeftPressed,
    required this.onRightPressed,
    required this.onOkPressed,
    this.menuKeyLabel = 'ホーム',
    this.stampKeyLabel = 'スタンプ',
    this.saveShareKeyLabel = '保存/シェア',
    this.systemMessage,
    this.menuWidget,
  });

  final Widget preview;
  final bool isBusy;
  final bool photoLoaded;
  final String modeLabel;
  final String selectionLabel;
  final VoidCallback onMenuPressed;
  final VoidCallback onStampPressed;
  final VoidCallback onSaveSharePressed;
  final VoidCallback onUpPressed;
  final VoidCallback onDownPressed;
  final VoidCallback onLeftPressed;
  final VoidCallback onRightPressed;
  final VoidCallback onOkPressed;
  final String menuKeyLabel;
  final String stampKeyLabel;
  final String saveShareKeyLabel;
  final String? systemMessage;
  final Widget? menuWidget;

  @override
  Widget build(BuildContext context) {
    // 全画面ガラケー：画面いっぱいに表示。
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _ShellMetrics metrics = _ShellMetrics.from(constraints.biggest);
        return Stack(
          children: <Widget>[
            // 全画面フィルでガラケー本体を表示
            Positioned.fill(
              child: _PhoneBody(
                metrics: metrics,
                preview: preview,
                menuWidget: menuWidget,
                photoLoaded: photoLoaded,
                modeLabel: modeLabel,
                selectionLabel: selectionLabel,
                systemMessage: systemMessage,
                onMenuPressed: onMenuPressed,
                onStampPressed: onStampPressed,
                onSaveSharePressed: onSaveSharePressed,
                onUpPressed: onUpPressed,
                onDownPressed: onDownPressed,
                onLeftPressed: onLeftPressed,
                onRightPressed: onRightPressed,
                onOkPressed: onOkPressed,
                menuKeyLabel: menuKeyLabel,
                stampKeyLabel: stampKeyLabel,
                saveShareKeyLabel: saveShareKeyLabel,
              ),
            ),
            if (isBusy)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x3AFFC0CB),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.pink),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
