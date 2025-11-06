import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeOverlayPainterWidget extends CustomPainter {
  final Barcode barcode;

  BarcodeOverlayPainterWidget(this.barcode);

  @override
  void paint(Canvas canvas, Size size) {
    final corners = barcode.corners;
    if (corners.isEmpty || corners.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(corners.first.dx, corners.first.dy);
    for (final point in corners.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    canvas.drawPath(path, paint);

    final glow = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.4)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// checked
