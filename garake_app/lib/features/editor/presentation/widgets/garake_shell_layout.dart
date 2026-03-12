part of 'garake_shell.dart';

// 全画面ガラケー本体。上部＝画面エリア（リアルフレーム付き）+ ヒンジ + 下部＝カワイイ風キーパッド。
class _PhoneBody extends StatelessWidget {
  const _PhoneBody({
    required this.metrics,
    required this.preview,
    required this.menuWidget,
    required this.photoLoaded,
    required this.modeLabel,
    required this.selectionLabel,
    required this.systemMessage,
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
  });

  final _ShellMetrics metrics;
  final Widget preview;
  final Widget? menuWidget;
  final bool photoLoaded;
  final String modeLabel;
  final String selectionLabel;
  final String? systemMessage;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF5C0D8),
            Color(0xFFF0A8C8),
            Color(0xFFE890B8),
            Color(0xFFF0A8C8),
            Color(0xFFF5C0D8),
          ],
        ),
        borderRadius: BorderRadius.circular(metrics.phoneCornerRadius),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 20,
            offset: Offset(4, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // 画面エリアは上部の約2/3を占有する。
          Expanded(
            flex: 66,
            child: _DisplaySection(
              metrics: metrics,
              preview: preview,
              menuWidget: menuWidget,
              photoLoaded: photoLoaded,
              modeLabel: modeLabel,
              selectionLabel: selectionLabel,
              systemMessage: systemMessage,
            ),
          ),
          Expanded(
            flex: 34,
            child: _KeypadSection(
              metrics: metrics,
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
        ],
      ),
    );
  }
}

// ディスプレイエリア。リアルなガラケー筐体フレーム（スピーカー + カメラ + 厚いベゼル + ハイライト）。
class _DisplaySection extends StatelessWidget {
  const _DisplaySection({
    required this.metrics,
    required this.preview,
    required this.menuWidget,
    required this.photoLoaded,
    required this.modeLabel,
    required this.selectionLabel,
    required this.systemMessage,
  });

  final _ShellMetrics metrics;
  final Widget preview;
  final Widget? menuWidget;
  final bool photoLoaded;
  final String modeLabel;
  final String selectionLabel;
  final String? systemMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFF5C0D8), Color(0xFFE8A0B8)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(metrics.phoneCornerRadius),
          topRight: Radius.circular(metrics.phoneCornerRadius),
        ),
      ),
      child: Column(
        children: <Widget>[
          _SpeakerArea(metrics: metrics),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.frameOuterPad,
                0,
                metrics.frameOuterPad,
                8 * metrics.scale,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(metrics.frameOuterRadius),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF1A1A1A), Color(0xFF232323)],
                  ),
                  border: Border.all(
                    color: const Color(0xFF2F2F2F),
                    width: 1.5,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(metrics.frameMiddlePad),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      metrics.frameMiddleRadius,
                    ),
                    color: const Color(0xFF111111),
                    border: Border.all(
                      color: const Color(0xFF363636),
                      width: 1.0,
                    ),
                  ),
                  padding: EdgeInsets.all(metrics.frameInnerPad),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(metrics.screenRadius),
                      color: const Color(0xFF050510),
                      border: Border.all(
                        color: const Color(0xFF161820),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        metrics.screenRadius - 1,
                      ),
                      child: Column(
                        children: <Widget>[
                          _StatusBar(
                            metrics: metrics,
                            photoLoaded: photoLoaded,
                            modeLabel: modeLabel,
                            selectionLabel: selectionLabel,
                          ),
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                menuWidget ?? preview,
                                if (systemMessage != null &&
                                    systemMessage!.isNotEmpty)
                                  _SystemMessageOverlay(
                                    metrics: metrics,
                                    message: systemMessage!,
                                  ),
                              ],
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
      ),
    );
  }
}

// スピーカーグリル＋カメラレンズエリア（画面上部）。
class _SpeakerArea extends StatelessWidget {
  const _SpeakerArea({required this.metrics});
  final _ShellMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: metrics.speakerTopPad,
        bottom: metrics.speakerBottomPad,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(8, (int index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5 * metrics.scale),
            child: Container(
              width: 3 * metrics.scale,
              height: 3 * metrics.scale,
              decoration: const BoxDecoration(
                color: Color(0xFFC07898),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// システムメッセージオーバーレイ。
class _SystemMessageOverlay extends StatelessWidget {
  const _SystemMessageOverlay({required this.metrics, required this.message});

  final _ShellMetrics metrics;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.all(8 * metrics.scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE53A1020),
            border: Border.all(color: AppTheme.pinkLight, width: 1),
            borderRadius: BorderRadius.circular(8 * metrics.scale),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * metrics.scale,
              vertical: 6 * metrics.scale,
            ),
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10 * metrics.scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFE4EC),
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ステータスバー。キャリアアイコン + 時計 + バッテリー。
class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.metrics,
    required this.photoLoaded,
    required this.modeLabel,
    required this.selectionLabel,
  });

  final _ShellMetrics metrics;
  final bool photoLoaded;
  final String modeLabel;
  final String selectionLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final String centerText = photoLoaded
        ? '$modeLabel  $selectionLabel'
        : l10n.formatDateStamp(now);

    return Container(
      height: metrics.statusBarHeight,
      padding: EdgeInsets.symmetric(horizontal: metrics.statusHorizontalInset),
      color: const Color(0xFF111111),
      child: Row(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                l10n.statusCarrierMark,
                style: TextStyle(
                  fontSize: metrics.statusIconText,
                  color: const Color(0xFFB0B0B0),
                ),
              ),
              SizedBox(width: 3 * metrics.scale),
              _SignalBars(metrics: metrics),
            ],
          ),
          SizedBox(width: metrics.statusGap),
          Expanded(
            child: Text(
              centerText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: metrics.statusMetaText,
                color: const Color(0xFFB0B0B0),
                letterSpacing: 0.4,
              ),
            ),
          ),
          SizedBox(width: metrics.statusGap),
          _BatteryIcon(metrics: metrics),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.metrics});

  final _ShellMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10 * metrics.scale,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int i = 0; i < 4; i++) ...<Widget>[
            if (i > 0) SizedBox(width: 1 * metrics.scale),
            Container(
              width: 2 * metrics.scale,
              height: (4 + i * 2) * metrics.scale,
              color: const Color(0xFF90D090),
            ),
          ],
        ],
      ),
    );
  }
}

// バッテリーアイコン。Figmaの薄緑ゲージ。
class _BatteryIcon extends StatelessWidget {
  const _BatteryIcon({required this.metrics});
  final _ShellMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: metrics.batteryWidth,
          height: metrics.batteryHeight,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF90D090), width: 1),
            borderRadius: BorderRadius.circular(1 * metrics.scale),
            color: const Color(0xFF111111),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: metrics.batteryWidth * 0.72,
            height: metrics.batteryHeight - 3 * metrics.scale,
            margin: const EdgeInsets.only(left: 2),
            color: const Color(0xFF90D090),
          ),
        ),
        Container(
          width: 2 * metrics.scale,
          height: metrics.batteryHeight * 0.54,
          color: const Color(0xFF90D090),
        ),
      ],
    );
  }
}
