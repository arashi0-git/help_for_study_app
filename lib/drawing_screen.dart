import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'drawing_point.dart';
import 'drawing_painter.dart';
import 'mathpix_service.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({Key? key}) : super(key: key);

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  List<DrawingPoint> _points = [];
  List<List<DrawingPoint>> _paths = [];
  String _recognizedText = '';

  Paint _newPaint() {
    return Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
  }

  Future<void> _processWithMLKit() async {
    RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = bytes!.buffer.asUint8List();

    final InputImage inputImage = InputImage.fromBytes(
      bytes: pngBytes,
      inputImageData: InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: InputImageRotation.rotation0deg,
        inputImageFormat: InputImageFormat.bgra8888,
        planeData: [],
      ),
    );

    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    setState(() {
      _recognizedText = recognizedText.text;
    });
  }

  Future<void> _processWithMathpix() async {
    RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = bytes!.buffer.asUint8List();

    setState(() {
      _recognizedText = '数式解析中...';
    });

    try {
      String result = await recognizeMathpix(pngBytes);
      setState(() {
        _recognizedText = result;
      });
    } catch (e) {
      setState(() {
        _recognizedText = 'Mathpixエラー: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing App'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: _processWithMLKit),       // ML Kit
          IconButton(icon: Icon(Icons.functions), onPressed: _processWithMathpix),  // Mathpix
          IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _points.clear();
                  _paths.clear();
                });
              }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _points = [DrawingPoint(point: details.localPosition, paint: _newPaint())];
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(DrawingPoint(point: details.localPosition, paint: _newPaint()));
                  });
                },
                onPanEnd: (details) {
                  _paths.add(List.from(_points));
                  _points.clear();
                },
                child: CustomPaint(
                  painter: DrawingPainter(points: [..._paths.expand((e) => e), ..._points]),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            width: double.infinity,
            child: Text(
              '認識結果: $_recognizedText',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
