part of 'garake_shell.dart';

// IMG_2195スタイルのキーパッド。ソフトキー + D-pad + OK + 通話/終了 + ラベルキー。カワイイ風配色。
class _KeypadSection extends StatelessWidget {
  const _KeypadSection({
    required this.metrics,
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
    return DecoratedBox(
      // カワイイ風ピンクグラデーションのキーパッド背景
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFFFF0F5),
            Color(0xFFFFD6E0),
            Color(0xFFFFBCD0),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(
            metrics.phoneWidth * 0.6,
            metrics.keypadCurve,
          ),
          topRight: Radius.elliptical(
            metrics.phoneWidth * 0.6,
            metrics.keypadCurve,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.keypadHorizontalInset,
          metrics.keypadTopInset,
          metrics.keypadHorizontalInset,
          metrics.keypadBottomInset,
        ),
        child: Column(
          children: <Widget>[
            // ソフトキー 2つ横並び
            Row(
              children: <Widget>[
                Expanded(child: _SoftKey(metrics: metrics)),
                SizedBox(width: metrics.keyGapLarge),
                Expanded(child: _SoftKey(metrics: metrics)),
              ],
            ),
            SizedBox(height: metrics.keyGapMedium),
            // D-pad + 通話/終了ボタン
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _CallActionKey(metrics: metrics, isCall: true),
                  SizedBox(width: metrics.keyGapSmall),
                  Expanded(
                    child: _NavigationPad(
                      metrics: metrics,
                      onUpPressed: onUpPressed,
                      onDownPressed: onDownPressed,
                      onLeftPressed: onLeftPressed,
                      onRightPressed: onRightPressed,
                      onOkPressed: onOkPressed,
                    ),
                  ),
                  SizedBox(width: metrics.keyGapSmall),
                  _CallActionKey(metrics: metrics, isCall: false),
                ],
              ),
            ),
            SizedBox(height: metrics.keyGapMedium),
            // 下段ラベルキー 3つ（メニュー/スタンプ/保存シェア）
            Row(
              children: <Widget>[
                Expanded(
                  child: _LabelKey(
                    metrics: metrics,
                    label: menuKeyLabel,
                    onPressed: () => _triggerKeyPress(onMenuPressed),
                    keyId: const Key('menu-button'),
                  ),
                ),
                SizedBox(width: metrics.keyGapTiny),
                Expanded(
                  child: _LabelKey(
                    metrics: metrics,
                    label: stampKeyLabel,
                    onPressed: () => _triggerKeyPress(onStampPressed),
                    keyId: const Key('stamp-button'),
                  ),
                ),
                SizedBox(width: metrics.keyGapTiny),
                Expanded(
                  child: _LabelKey(
                    metrics: metrics,
                    label: saveShareKeyLabel,
                    onPressed: () => _triggerKeyPress(onSaveSharePressed),
                    keyId: const Key('save-share-button'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ソフトキー（横線マーク付き）
class _SoftKey extends StatelessWidget {
  const _SoftKey({required this.metrics});
  final _ShellMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.softKeyHeight,
      decoration: _kawaiiKeyDecoration(metrics),
      alignment: Alignment.center,
      child: Container(
        width: metrics.lineMarkWidth,
        height: 3,
        color: const Color(0xFFA06080),
      ),
    );
  }
}

// 通話/終了ボタン（ハート型アクセント）
class _CallActionKey extends StatelessWidget {
  const _CallActionKey({required this.metrics, required this.isCall});
  final _ShellMetrics metrics;
  final bool isCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.callKeyWidth,
      height: metrics.callKeyHeight,
      decoration: _kawaiiKeyDecoration(metrics),
      child: Icon(
        isCall ? Icons.call : Icons.call_end,
        size: metrics.callIconSize,
        color: isCall ? const Color(0xFF2AB65D) : AppTheme.heartRed,
      ),
    );
  }
}

// D-pad（十字キー + OKボタン）
class _NavigationPad extends StatelessWidget {
  const _NavigationPad({
    required this.metrics,
    required this.onUpPressed,
    required this.onDownPressed,
    required this.onLeftPressed,
    required this.onRightPressed,
    required this.onOkPressed,
  });

  final _ShellMetrics metrics;
  final VoidCallback onUpPressed;
  final VoidCallback onDownPressed;
  final VoidCallback onLeftPressed;
  final VoidCallback onRightPressed;
  final VoidCallback onOkPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.navPadHeight,
      decoration: _kawaiiKeyDecoration(metrics),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 上矢印
          Positioned(
            top: 2,
            child: _ArrowKey(
              metrics: metrics,
              icon: Icons.keyboard_arrow_up,
              onPressed: onUpPressed,
            ),
          ),
          // 下矢印
          Positioned(
            bottom: 2,
            child: _ArrowKey(
              metrics: metrics,
              icon: Icons.keyboard_arrow_down,
              onPressed: onDownPressed,
            ),
          ),
          // 左矢印
          Positioned(
            left: 2,
            child: _ArrowKey(
              metrics: metrics,
              icon: Icons.keyboard_arrow_left,
              onPressed: onLeftPressed,
            ),
          ),
          // 右矢印
          Positioned(
            right: 2,
            child: _ArrowKey(
              metrics: metrics,
              icon: Icons.keyboard_arrow_right,
              onPressed: onRightPressed,
            ),
          ),
          // 中央OKボタン
          GestureDetector(
            key: const Key('ok-button'),
            onTap: () => _triggerKeyPress(onOkPressed),
            child: Container(
              width: metrics.okWidth,
              height: metrics.okHeight,
              decoration: _kawaiiKeyDecoration(
                metrics,
                radius: metrics.okRadius,
              ),
              alignment: Alignment.center,
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: metrics.okTextSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6A2040),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 矢印キー個別
class _ArrowKey extends StatelessWidget {
  const _ArrowKey({
    required this.metrics,
    required this.icon,
    required this.onPressed,
  });
  final _ShellMetrics metrics;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _triggerKeyPress(onPressed),
      child: SizedBox(
        width: metrics.arrowKeyWidth,
        height: metrics.arrowKeyHeight,
        child: Icon(
          icon,
          size: metrics.arrowIconSize,
          color: const Color(0xFFA06080),
        ),
      ),
    );
  }
}

// ラベル付きキー（メニュー/スタンプ/保存シェア）
class _LabelKey extends StatelessWidget {
  const _LabelKey({
    required this.metrics,
    required this.label,
    required this.onPressed,
    required this.keyId,
  });
  final _ShellMetrics metrics;
  final String label;
  final VoidCallback onPressed;
  final Key keyId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: keyId,
      onTap: onPressed,
      child: Container(
        height: metrics.labelKeyHeight,
        decoration: _kawaiiKeyDecoration(metrics),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: metrics.labelTextSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6A2040),
            ),
          ),
        ),
      ),
    );
  }
}

// カワイイ風ボタンのデコレーション。ピンクグラデーション。
BoxDecoration _kawaiiKeyDecoration(_ShellMetrics metrics, {double? radius}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius ?? metrics.keyRadius),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFFFF5F8), Color(0xFFFFDAE5)],
    ),
    border: Border.all(color: const Color(0xFFE0A0B8), width: 1),
    boxShadow: const <BoxShadow>[
      BoxShadow(
        color: Color(0x28CC6080),
        blurRadius: 1.5,
        offset: Offset(0, 1),
      ),
    ],
  );
}

// レイアウト寸法。全画面ガラケー用。
class _ShellMetrics {
  const _ShellMetrics._({
    required this.phoneWidth,
    required this.phoneHeight,
    required this.scale,
  });

  factory _ShellMetrics.from(Size viewport) {
    return _ShellMetrics._(
      phoneWidth: viewport.width,
      phoneHeight: viewport.height,
      scale: viewport.width / 320,
    );
  }

  final double phoneWidth;
  final double phoneHeight;
  final double scale;

  // 筐体
  double get phoneCornerRadius => 18 * scale;
  double get hingeHeight => 10 * scale;

  // スピーカー＋カメラエリア
  double get speakerTopPad => 10 * scale;
  double get speakerBottomPad => 6 * scale;
  double get cameraLensSize => 14 * scale;

  // フレーム（ネストベゼル）
  double get frameOuterPad => 12 * scale;
  double get frameOuterRadius => 10 * scale;
  double get frameMiddlePad => 6 * scale;
  double get frameMiddleRadius => 7 * scale;
  double get frameInnerPad => 4 * scale;
  double get screenRadius => 4 * scale;

  // ステータスバー
  double get statusBarHeight => 24 * scale;
  double get statusHorizontalInset => 8 * scale;
  double get statusIconText => 11 * scale;
  double get statusMetaText => 8 * scale;
  double get statusGap => 5 * scale;

  // バッテリー
  double get batteryWidth => 22 * scale;
  double get batteryHeight => 12 * scale;

  // キーパッド
  double get keypadCurve => 18 * scale;
  double get keypadHorizontalInset => 16 * scale;
  double get keypadTopInset => 10 * scale;
  double get keypadBottomInset => 12 * scale;
  double get keyRadius => 8 * scale;
  double get softKeyHeight => 32 * scale;
  double get lineMarkWidth => 28 * scale;
  double get keyGapLarge => 72 * scale;
  double get keyGapMedium => 7 * scale;
  double get keyGapSmall => 7 * scale;
  double get keyGapTiny => 5 * scale;
  double get callKeyWidth => 54 * scale;
  double get callKeyHeight => 42 * scale;
  double get callIconSize => 22 * scale;
  double get navPadHeight => 82 * scale;
  double get arrowKeyWidth => 34 * scale;
  double get arrowKeyHeight => 24 * scale;
  double get arrowIconSize => 24 * scale;
  double get okWidth => 74 * scale;
  double get okHeight => 44 * scale;
  double get okRadius => 12 * scale;
  double get okTextSize => 17 * scale;
  double get labelKeyHeight => 44 * scale;
  double get labelTextSize => 12 * scale;
}
