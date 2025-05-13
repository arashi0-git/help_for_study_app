import 'package:flutter/material.dart';
import 'drawing_point.dart';

class DrawingCanvas extends StatelessWidget {
    final List<List<DrawingPoint>> paths;
    
    const DrawingCanvas({Key? key, required this.paths}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return CustomPoint(
            painter: _DrawingPointer(paths: paths),
            size: Size.infinite,
        );
    }
}

class _DrawingPointer extends CustomPainter {
    final List<List<DrawingPoint>> paths;

    _DrawingPointer({required this.paths});
    
    @override
    void paint(Canvas canvas, Size size) {
        for (var path in paths) {
            for (int i = 0; i < path.length - 1; i++) {
                if (path[i] != null && path[i + 1] != null) {
                    canvas.drawLine(path[i].point, path[i + 1].point, path[i].paint);
                }
            }
        }
    }

    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
    
