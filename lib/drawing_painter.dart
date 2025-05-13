import 'package:flutter/material.dart';
import 'drawing_point.dart';

class DrawingPainter extends CustomPainter {
    final List<DrawingPoint> points;

    DrawingPainter({required this.points});

    @override
    void paint(Canvas canvas, Size size) {
        for (int i = 0; i < points.length - 1; i++) {
            if (points[i] != null && points[i + 1] != null) {
                canvas.drawLine(points[i].point, points[i + 1].point, points[i].paint);
            }
        }
    }

    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
