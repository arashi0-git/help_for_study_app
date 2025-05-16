import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../mathpix_service.dart';

class HandwritingRecognitionScreen extends StatefulWidget {
  const HandwritingRecognitionScreen({super.key});

  @override
  State<HandwritingRecognitionScreen> createState() => _HandwritingRecognitionScreenState();
}

class _HandwritingRecognitionScreenState extends State<HandwritingRecognitionScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 4,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String _recognizedText = '';

  Future<void> _recognizeText() async {
    try {
      final Uint8List? pngBytes = await _controller.toPngBytes();
      if (pngBytes == null) return;
      setState(() {
        _recognizedText = '認識中...';
      });
      String result = await recognizeMathpix(pngBytes);
      setState(() {
        _recognizedText = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手書き認識'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 300,
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _controller.clear,
                  child: const Text('クリア'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _recognizeText,
                  child: const Text('認識開始'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _recognizedText.isEmpty ? '認識結果がここに表示されます' : _recognizedText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
