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
    required this.onMenuPressed,
    required this.onStampPressed,
    required this.onSaveSharePressed,
    required this.onUpPressed,
    required this.onDownPressed,
    required this.onLeftPressed,
    required this.onRightPressed,
    required this.onOkPressed,
    required this.menuKeyLabel,
    required this.stampKeyLabel,
    required this.saveShareKeyLabel,
  });

  final _ShellMetrics metrics;
  final Widget preview;
  final Widget? menuWidget;
  final bool photoLoaded;
  final String modeLabel;
  final String selectionLabel;
  final String? systemMessage;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // 上部：画面エリア（リアルフレーム付き）
        Expanded(
          flex: 58,
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
        // ヒンジ帯
        _HingeBand(metrics: metrics),
        // 下部：キーパッド
        Expanded(
          flex: 42,
          child: _KeypadSection(
            metrics: metrics,
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
      ],
    );
  }
}

// ヒンジ帯。折りたたみ部分のメタリックな横帯。
class _HingeBand extends StatelessWidget {
  const _HingeBand({required this.metrics});
  final _ShellMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.hingeHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF3A1828),
            Color(0xFF5A2840),
            Color(0xFF6A3050),
            Color(0xFF5A2840),
            Color(0xFF3A1828),
          ],
          stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // ヒンジの光沢ライン
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(height: 1, color: const Color(0x40FFB3C6)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 1, color: const Color(0x30FFB3C6)),
          ),
          // ヒンジ中央のくぼみ
          Center(
            child: Container(
              width: metrics.phoneWidth * 0.35,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF2A0E1C),
                borderRadius: BorderRadius.circular(1),
              ),
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
      // 筐体全体の背景（ダークベリー）
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF200E18), Color(0xFF180810)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(metrics.phoneCornerRadius),
          topRight: Radius.circular(metrics.phoneCornerRadius),
        ),
      ),
      child: Column(
        children: <Widget>[
          // スピーカー＋カメラエリア
          _SpeakerArea(metrics: metrics),
          // メイン画面（多重ベゼル）
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.frameOuterPad,
                0,
                metrics.frameOuterPad,
                metrics.frameOuterPad * 0.6,
              ),
              child: Container(
                // 外枠：暗いベゼル（筐体フレーム）
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(metrics.frameOuterRadius),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF3A1828),
                      Color(0xFF2D1520),
                      Color(0xFF1A0A10),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFF5A2840), width: 2),
                  boxShadow: const <BoxShadow>[
                    // 内側にインセットシャドウっぽい効果
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(metrics.frameMiddlePad),
                child: Container(
                  // 中枠：少し明るいベゼル＋ハイライト
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      metrics.frameMiddleRadius,
                    ),
                    color: const Color(0xFF0E0508),
                    border: Border.all(
                      color: const Color(0xFF6A3550),
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.all(metrics.frameInnerPad),
                  child: Container(
                    // 最内枠：LCD画面のフレーム
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(metrics.screenRadius),
                      color: const Color(0xFF050205),
                      border: Border.all(
                        color: const Color(0xFF3A1A28),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        metrics.screenRadius - 1,
                      ),
                      child: Column(
                        children: <Widget>[
                          // ステータスバー
                          _StatusBar(
                            metrics: metrics,
                            photoLoaded: photoLoaded,
                            modeLabel: modeLabel,
                            selectionLabel: selectionLabel,
                          ),
                          // メインコンテンツ
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
          // 画面下のメーカーロゴ風テキスト
          Padding(
            padding: EdgeInsets.only(bottom: 4 * metrics.scale),
            child: Text(
              '✿ garake ✿',
              style: TextStyle(
                fontSize: 7 * metrics.scale,
                color: const Color(0xFF4A2535),
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
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
      padding: EdgeInsets.fromLTRB(
        metrics.frameOuterPad,
        metrics.speakerTopPad,
        metrics.frameOuterPad,
        metrics.speakerBottomPad,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // カメラレンズ
          _CameraLens(metrics: metrics),
          SizedBox(width: 10 * metrics.scale),
          // スピーカーグリル
          _SpeakerGrille(metrics: metrics),
          SizedBox(width: 10 * metrics.scale),
          // サブカメラ（小さな点）
          Container(
            width: 4 * metrics.scale,
            height: 4 * metrics.scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A0A10),
              border: Border.all(color: const Color(0xFF3A1828), width: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// カメラレンズ風アイコン。
class _CameraLens extends StatelessWidget {
  const _CameraLens({required this.metrics});
  final _ShellMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.cameraLensSize,
      height: metrics.cameraLensSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: <Color>[
            Color(0xFF2A1520),
            Color(0xFF1A0A10),
            Color(0xFF0A0408),
          ],
          stops: <double>[0.0, 0.6, 1.0],
        ),
        border: Border.all(color: const Color(0xFF5A3545), width: 1.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x40FF8FAB), blurRadius: 3, spreadRadius: 0),
        ],
      ),
      child: Center(
        child: Container(
          width: metrics.cameraLensSize * 0.4,
          height: metrics.cameraLensSize * 0.4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1A0814),
          ),
        ),
      ),
    );
  }
}

// スピーカーグリル。
class _SpeakerGrille extends StatelessWidget {
  const _SpeakerGrille({required this.metrics});
  final _ShellMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final int slotCount = 7;
    final double slotWidth = 3.0 * metrics.scale;
    final double slotHeight = 1.5 * metrics.scale;
    final double gap = 2.0 * metrics.scale;
    final double totalWidth = slotCount * slotWidth + (slotCount - 1) * gap;

    return Container(
      width: totalWidth + 8 * metrics.scale,
      height: slotHeight * 3 + gap * 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3 * metrics.scale),
        color: const Color(0xFF1A0A10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int row = 0; row < 3; row++) ...<Widget>[
            if (row > 0) SizedBox(height: gap * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int col = 0; col < slotCount; col++) ...<Widget>[
                  if (col > 0) SizedBox(width: gap),
                  Container(
                    width: slotWidth,
                    height: slotHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(slotHeight * 0.5),
                      color: const Color(0xFF0A0408),
                      border: Border.all(
                        color: const Color(0xFF2A1520),
                        width: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
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
    return Container(
      height: metrics.statusBarHeight,
      padding: EdgeInsets.symmetric(horizontal: metrics.statusHorizontalInset),
      color: const Color(0xFF120610),
      child: Row(
        children: <Widget>[
          Text(
            '✿ ıll',
            style: TextStyle(
              fontSize: metrics.statusIconText,
              fontWeight: FontWeight.w800,
              color: AppTheme.pinkLight,
              letterSpacing: 0.25,
            ),
          ),
          SizedBox(width: metrics.statusGap),
          Expanded(
            child: Text(
              photoLoaded ? '$modeLabel  $selectionLabel' : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: metrics.statusMetaText,
                color: AppTheme.pinkLight,
                letterSpacing: 0.15,
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

// バッテリーアイコン。ピンクゲージ。
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
            border: Border.all(color: AppTheme.pinkLight, width: 1),
            color: const Color(0xFF120610),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: metrics.batteryWidth * 0.72,
            height: metrics.batteryHeight - 4,
            margin: const EdgeInsets.only(left: 2),
            color: AppTheme.pink,
          ),
        ),
        Container(
          width: 2,
          height: metrics.batteryHeight * 0.54,
          color: AppTheme.pinkLight,
        ),
      ],
    );
  }
}
