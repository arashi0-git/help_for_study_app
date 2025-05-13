import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'drawing_point.dart';
import 'drawing_provider.dart';
import 'drawing_canvas.dart';

class DrawingScreen extends StatefulWidget {
    const DrawingScreen({Key? key}) : super(key: key);

    @override
    State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
    List<DrawingPoint> _currentPath = [];

    Paint _newPaint() {
        return Paint()
            ..color = Colors.black
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round;
    }

    @override
    Widget build(BuildContext context) {
        final provider = Provider.of<DrawingProvider>(context);
        return Scaffold(
            appBar: AppBar(
                title: Text('Drawing App'),
                actions:[
                    IconButton(icon: Icon(Icons.undo), onPressed: provider.undo ),
                    IconButton(icon: Icon(Icons.redo), onPressed: provider.redo),
                    IconButton(icon: Icon(Icons.clear), onPressed: provider.clear),
                ],
            ),
            body: GestureDetector(
                onPanStart: (details) {
                    setState(() {
                        _currentPath = [DrawingPoint(point: details.localPosition, paint: _newPaint())];
                    });
                },
                onPanUpdate: (details) {
                    setState(() {
                        _currentPath.add(DrawingPoint(point: details.localPosition, paint: _newPaint()));
                    });
                },
                onPanEnd: (details) {
                    provider.addPath(_currentPath);
                    _currentPath = [];
                },
                child: Stack(
                    children: [
                        DrawingCanvas(paths: provider.currentPaths),
                        CustomPaint(
                            painter: _DrawingPainter(paths: [_currentPath]),
                            size: Size.infinite,
                        )
                    ],
                ),
            ),
        );
    }
}

class _DrawingPainter extends CustomPainter {
    final List<List<DrawingPoint>> paths;

    _DrawingPainter({required this.paths});

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
