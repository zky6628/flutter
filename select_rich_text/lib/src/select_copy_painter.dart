import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CopyPainter extends CustomPainter {
  CopyPainter({this.color = Colors.blue});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double radius = size.width / 2.0;
    final Rect circle =
        Rect.fromCircle(center: Offset(radius, radius), radius: radius);
    final Rect point = Rect.fromLTWH(0.0, 0.0, radius, radius);
    final Path path = Path()
      ..addOval(circle)
      ..addRect(point);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CopyPainter oldPainter) {
    return color != oldPainter.color;
  }
}
