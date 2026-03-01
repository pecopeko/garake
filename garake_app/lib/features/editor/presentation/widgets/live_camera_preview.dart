// Renders an in-app camera preview so capture can stay inside the garake shell.
/*
Dependency Memo
- Depends on: camera.dart for live camera frame rendering.
- Requires methods: CameraValue.isInitialized.
- Provides methods: LiveCameraPreview.build().
*/
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LiveCameraPreview extends StatelessWidget {
  const LiveCameraPreview({
    super.key,
    required this.controller,
    required this.isInitializing,
    required this.errorMessage,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
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
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'カメラを起動中...',
            style: TextStyle(
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
      ],
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
