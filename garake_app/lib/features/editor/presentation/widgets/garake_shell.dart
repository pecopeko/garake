// カワイイ風全画面ガラケーシェル。IMG_2195のレイアウト + framework.JPGの装飾。
/*
Dependency Memo
- Depends on: Flutter Material/Services, caller-provided preview/menu widgets, keypad callbacks, AppTheme colors.
- Requires methods: onModeTogglePressed(), onMenuPressed(), onStampPressed(), onSaveSharePressed(), onUpPressed(), onDownPressed(), onLeftPressed(), onRightPressed(), onOkPressed(), HapticFeedback.selectionClick().
- Provides methods: GarakeShell.build().
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_localizations.dart';
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
    required this.busyLabel,
    required this.photoLoaded,
    required this.modeLabel,
    required this.selectionLabel,
    required this.onModeTogglePressed,
    required this.onMenuPressed,
    required this.onStampPressed,
    required this.onSaveSharePressed,
    required this.onUpPressed,
    required this.onDownPressed,
    required this.onLeftPressed,
    required this.onRightPressed,
    required this.onOkPressed,
    required this.modeToggleLabel,
    required this.menuKeyLabel,
    required this.stampKeyLabel,
    required this.decorateKeyLabel,
    required this.saveShareKeyLabel,
    this.systemMessage,
    this.menuWidget,
  });

  final Widget preview;
  final bool isBusy;
  final String? busyLabel;
  final bool photoLoaded;
  final String modeLabel;
  final String selectionLabel;
  final VoidCallback onModeTogglePressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onStampPressed;
  final VoidCallback onSaveSharePressed;
  final VoidCallback onUpPressed;
  final VoidCallback onDownPressed;
  final VoidCallback onLeftPressed;
  final VoidCallback onRightPressed;
  final VoidCallback onOkPressed;
  final String modeToggleLabel;
  final String menuKeyLabel;
  final String stampKeyLabel;
  final String decorateKeyLabel;
  final String saveShareKeyLabel;
  final String? systemMessage;
  final Widget? menuWidget;

  @override
  Widget build(BuildContext context) {
    // 全画面ガラケー：画面いっぱいに表示。
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final AppLocalizations l10n = context.l10n;
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
                onModeTogglePressed: onModeTogglePressed,
                onMenuPressed: onMenuPressed,
                onStampPressed: onStampPressed,
                onSaveSharePressed: onSaveSharePressed,
                onUpPressed: onUpPressed,
                onDownPressed: onDownPressed,
                onLeftPressed: onLeftPressed,
                onRightPressed: onRightPressed,
                onOkPressed: onOkPressed,
                modeToggleLabel: modeToggleLabel,
                menuKeyLabel: menuKeyLabel,
                stampKeyLabel: stampKeyLabel,
                decorateKeyLabel: decorateKeyLabel,
                saveShareKeyLabel: saveShareKeyLabel,
              ),
            ),
            if (isBusy)
              Positioned.fill(
                child: IgnorePointer(
                  // 加工中でもホームキーだけは押せるようにオーバーレイは透過させる。
                  child: ColoredBox(
                    color: const Color(0x3AFFC0CB),
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xE5120610),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.pinkLight,
                            width: 1,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CircularProgressIndicator(
                                strokeWidth: 2.8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.pink,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                busyLabel ?? l10n.busyLoading,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFE6F0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
