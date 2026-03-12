// Renders an in-app camera preview so photo and video capture stay inside the garake shell.
/*
Dependency Memo
- Depends on: camera.dart for live camera frame rendering.
- Requires methods: CameraValue.isInitialized.
- Provides methods: LiveCameraPreview.build().
*/
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';

class LiveCameraPreview extends StatelessWidget {
  const LiveCameraPreview({
    super.key,
    required this.controller,
    required this.isInitializing,
    required this.errorMessage,
    required this.statusLabel,
    required this.hintLabel,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? errorMessage;
  final String statusLabel;
  final String hintLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (errorMessage != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE3E7F2),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    if (isInitializing ||
        controller == null ||
        !controller!.value.isInitialized) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            l10n.cameraInitializingLabel,
            style: const TextStyle(
              color: Color(0xFFD9DFEE),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.previewSize!.height,
              height: controller!.value.previewSize!.width,
              child: CameraPreview(controller!),
            ),
          ),
        ),
        // 疑似スキャンラインでガラケー液晶らしい見た目に寄せる。
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  const Color(0x11000000),
                  Colors.transparent,
                  const Color(0x14000000),
                ],
                stops: const <double>[0, 0.5, 1],
              ),
            ),
          ),
        ),
        IgnorePointer(child: CustomPaint(painter: _ScanlinePainter())),
        IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PreviewBadge(
                  label: statusLabel,
                  backgroundColor: const Color(0xCC2B1A25),
                ),
                const Spacer(),
                _PreviewBadge(
                  label: hintLabel,
                  backgroundColor: const Color(0xCC132E2C),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x80E9F0FF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF2F6FF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = const Color(0x12000000);
    const double spacing = 3.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) => false;
}
