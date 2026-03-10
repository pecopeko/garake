part of 'garake_shell.dart';

// Figmaノード15:2に寄せたキーパッド。上段切替キー + 中段操作キー + 下段4キー。
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
    final List<String> bottomLabels = _splitSaveShareLabel(
      menuLabel: menuKeyLabel,
      stampLabel: stampKeyLabel,
      saveShareLabel: saveShareKeyLabel,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF8D8E8),
            Color(0xFFF0C0D5),
            Color(0xFFE8B0C8),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8 * metrics.scale),
          topRight: Radius.circular(8 * metrics.scale),
          bottomLeft: Radius.circular(6 * metrics.scale),
          bottomRight: Radius.circular(6 * metrics.scale),
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
            _ModeToggleKey(
              metrics: metrics,
              onPressed: () => _triggerKeyPress(onMenuPressed),
            ),
            SizedBox(height: 10 * metrics.scale),
            Row(
              children: <Widget>[
                _SideActionKey(
                  metrics: metrics,
                  iconText: '📞',
                  onPressed: () => _triggerKeyPress(onMenuPressed),
                ),
                SizedBox(width: 8 * metrics.scale),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _SideArrowKey(
                        metrics: metrics,
                        label: '◀',
                        onPressed: () => _triggerKeyPress(onLeftPressed),
                      ),
                      SizedBox(width: 4 * metrics.scale),
                      _CenterNavPad(
                        metrics: metrics,
                        onUpPressed: onUpPressed,
                        onDownPressed: onDownPressed,
                        onOkPressed: onOkPressed,
                      ),
                      SizedBox(width: 4 * metrics.scale),
                      _SideArrowKey(
                        metrics: metrics,
                        label: '▶',
                        onPressed: () => _triggerKeyPress(onRightPressed),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8 * metrics.scale),
                _SideActionKey(
                  metrics: metrics,
                  iconText: '📕',
                  onPressed: () => _triggerKeyPress(onSaveSharePressed),
                ),
              ],
            ),
            SizedBox(height: 10 * metrics.scale),
            Row(
              children: <Widget>[
                Expanded(
                  child: _BottomSoftKey(
                    keyId: const Key('menu-button'),
                    metrics: metrics,
                    label: bottomLabels[0],
                    onPressed: () => _triggerKeyPress(onMenuPressed),
                  ),
                ),
                SizedBox(width: 4 * metrics.scale),
                Expanded(
                  child: _BottomSoftKey(
                    keyId: const Key('stamp-button'),
                    metrics: metrics,
                    label: bottomLabels[1],
                    onPressed: () => _triggerKeyPress(onStampPressed),
                  ),
                ),
                SizedBox(width: 4 * metrics.scale),
                Expanded(
                  child: _BottomSoftKey(
                    keyId: const Key('save-share-button'),
                    metrics: metrics,
                    label: bottomLabels[2],
                    onPressed: () => _triggerKeyPress(onSaveSharePressed),
                  ),
                ),
                SizedBox(width: 4 * metrics.scale),
                Expanded(
                  child: _BottomSoftKey(
                    metrics: metrics,
                    label: bottomLabels[3],
                    onPressed: () => _triggerKeyPress(onSaveSharePressed),
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

class _ModeToggleKey extends StatelessWidget {
  const _ModeToggleKey({required this.metrics, required this.onPressed});

  final _ShellMetrics metrics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 62 * metrics.scale,
        height: 30 * metrics.scale,
        alignment: Alignment.center,
        decoration: _pinkKeyDecoration(
          metrics,
          borderColor: const Color(0xFFC898B0),
          topColor: const Color(0xFFF0D0E0),
          bottomColor: const Color(0xFFE0B0C8),
          radius: 3 * metrics.scale,
        ),
        child: Text(
          '外cam  ⇄',
          style: TextStyle(
            color: const Color(0xFF704060),
            fontSize: 10 * metrics.scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SideActionKey extends StatelessWidget {
  const _SideActionKey({
    required this.metrics,
    required this.iconText,
    required this.onPressed,
  });

  final _ShellMetrics metrics;
  final String iconText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48 * metrics.scale,
        height: 32 * metrics.scale,
        alignment: Alignment.center,
        decoration: _silverKeyDecoration(metrics),
        child: Text(iconText, style: TextStyle(fontSize: 16 * metrics.scale)),
      ),
    );
  }
}

class _SideArrowKey extends StatelessWidget {
  const _SideArrowKey({
    required this.metrics,
    required this.label,
    required this.onPressed,
  });

  final _ShellMetrics metrics;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 26 * metrics.scale,
        height: 22 * metrics.scale,
        alignment: Alignment.center,
        decoration: _silverKeyDecoration(metrics),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF5D91B8),
            fontSize: 10 * metrics.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CenterNavPad extends StatelessWidget {
  const _CenterNavPad({
    required this.metrics,
    required this.onUpPressed,
    required this.onDownPressed,
    required this.onOkPressed,
  });

  final _ShellMetrics metrics;
  final VoidCallback onUpPressed;
  final VoidCallback onDownPressed;
  final VoidCallback onOkPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44 * metrics.scale,
      height: 72 * metrics.scale,
      child: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => _triggerKeyPress(onUpPressed),
              child: Container(
                alignment: Alignment.center,
                decoration: _pinkKeyDecoration(
                  metrics,
                  borderColor: const Color(0xFFB898A8),
                  topColor: const Color(0xFFF0E0E8),
                  bottomColor: const Color(0xFFD0B0C0),
                  radius: 3 * metrics.scale,
                ),
                child: Text(
                  '▲',
                  style: TextStyle(
                    color: const Color(0xFF906080),
                    fontSize: 10 * metrics.scale,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2 * metrics.scale),
          GestureDetector(
            key: const Key('ok-button'),
            onTap: () => _triggerKeyPress(onOkPressed),
            child: Container(
              width: 44 * metrics.scale,
              height: 28 * metrics.scale,
              alignment: Alignment.center,
              decoration: _pinkKeyDecoration(
                metrics,
                borderColor: const Color(0xFFA08098),
                topColor: const Color(0xFFFFFFFF),
                bottomColor: const Color(0xFFE0C8D5),
                radius: 3 * metrics.scale,
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: const Color(0xFF503040),
                  fontSize: 14 * metrics.scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 2 * metrics.scale),
          Expanded(
            child: GestureDetector(
              onTap: () => _triggerKeyPress(onDownPressed),
              child: Container(
                alignment: Alignment.center,
                decoration: _pinkKeyDecoration(
                  metrics,
                  borderColor: const Color(0xFFB898A8),
                  topColor: const Color(0xFFF0E0E8),
                  bottomColor: const Color(0xFFD0B0C0),
                  radius: 3 * metrics.scale,
                ),
                child: Text(
                  '▼',
                  style: TextStyle(
                    color: const Color(0xFF906080),
                    fontSize: 10 * metrics.scale,
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

class _BottomSoftKey extends StatelessWidget {
  const _BottomSoftKey({
    required this.metrics,
    required this.label,
    required this.onPressed,
    this.keyId,
  });

  final _ShellMetrics metrics;
  final String label;
  final VoidCallback onPressed;
  final Key? keyId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: keyId,
      onTap: onPressed,
      child: Container(
        height: 34 * metrics.scale,
        alignment: Alignment.center,
        decoration: _pinkKeyDecoration(
          metrics,
          borderColor: const Color(0xFFB098A8),
          topColor: const Color(0xFFF8F0F4),
          bottomColor: const Color(0xFFD8C0D0),
          radius: 4 * metrics.scale,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF503040),
              fontSize: 12 * metrics.scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _pinkKeyDecoration(
  _ShellMetrics metrics, {
  required Color borderColor,
  required Color topColor,
  required Color bottomColor,
  required double radius,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[topColor, bottomColor],
    ),
    border: Border.all(color: borderColor, width: 1.2 * metrics.scale),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x22000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
  );
}

BoxDecoration _silverKeyDecoration(_ShellMetrics metrics) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(4 * metrics.scale),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFE8E8E8), Color(0xFFD0D0D0), Color(0xFFC0C0C0)],
    ),
    border: Border.all(
      color: const Color(0xFFA0A0A0),
      width: 1.2 * metrics.scale,
    ),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x22000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
  );
}

List<String> _splitSaveShareLabel({
  required String menuLabel,
  required String stampLabel,
  required String saveShareLabel,
}) {
  final List<String> splitBySlash = saveShareLabel
      .split(RegExp(r'[/／]'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);
  final String saveLabel = splitBySlash.isNotEmpty ? splitBySlash.first : '保存';
  final String shareLabel = splitBySlash.length > 1 ? splitBySlash[1] : 'シェア';
  return <String>[menuLabel, stampLabel, saveLabel, shareLabel];
}

// 画面全体の比率に合わせる寸法定義。
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
      scale: viewport.width / 340,
    );
  }

  final double phoneWidth;
  final double phoneHeight;
  final double scale;

  double get phoneCornerRadius => 16 * scale;

  double get speakerTopPad => 10 * scale;
  double get speakerBottomPad => 6 * scale;
  double get cameraLensSize => 12 * scale;

  double get frameOuterPad => 16 * scale;
  double get frameOuterRadius => 4 * scale;
  double get frameMiddlePad => 6 * scale;
  double get frameMiddleRadius => 2 * scale;
  double get frameInnerPad => 2 * scale;
  double get screenRadius => 2 * scale;

  double get statusBarHeight => 21 * scale;
  double get statusHorizontalInset => 6 * scale;
  double get statusIconText => 10 * scale;
  double get statusMetaText => 10 * scale;
  double get statusGap => 5 * scale;

  double get batteryWidth => 16 * scale;
  double get batteryHeight => 8 * scale;

  double get keypadCurve => 8 * scale;
  double get keypadHorizontalInset => 12 * scale;
  double get keypadTopInset => 10 * scale;
  double get keypadBottomInset => 12 * scale;
}
