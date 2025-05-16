import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../mathpix_service.dart';
import '../services/rag_scoring_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ai_result_screen.dart';
import 'sympy.dart';

Future<Uint8List> addPaddingToImage(Uint8List pngBytes, {int padding = 40}) async {
  final codec = await ui.instantiateImageCodec(pngBytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();
  final width = image.width + padding * 2;
  final height = image.height + padding * 2;
  canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = Colors.white);
  canvas.drawImage(image, Offset(padding.toDouble(), padding.toDouble()), paint);
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

class HandwritingRecognitionScreen extends StatefulWidget {
  const HandwritingRecognitionScreen({super.key});

  @override
  State<HandwritingRecognitionScreen> createState() => _HandwritingRecognitionScreenState();
}

class _HandwritingRecognitionScreenState extends State<HandwritingRecognitionScreen> {
  late SignatureController _controller;
  String _recognizedText = '';
  String _rawResponse = '';
  bool _isProcessing = false;
  late RAGScoringService _ragScoringService;

  // 問題リスト（表示用とLaTeX用）
  final List<Map<String, String>> _problems = [
    {'display': 'x² + 4x + x² - 3x =', 'latex': 'x^{2} + 4x + x^{2} - 3x ='},
    {'display': '2x² - x + 5 - x =', 'latex': '2x^{2} - x + 5 - x ='},
    {'display': 'x² + 2x + 1 - 4 =', 'latex': 'x^{2} + 2x + 1 - 4 ='},
    {'display': '3x² - 7x + 2 + 5x =', 'latex': '3x^{2} - 7x + 2 + 5x ='},
    {'display': 'x² - 4x + 3x² - 2x =', 'latex': 'x^{2} - 4x + 3x^{2} - 2x ='},
  ];
  int _currentProblemIndex = 0;
  String _aiResult = '';
  String _aiRawResponse = '';

  void _nextProblem() {
    setState(() {
      _currentProblemIndex = (_currentProblemIndex + 1) % _problems.length;
      _aiResult = '';
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 8,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _initializeRAGService();
  }

  Future<void> _initializeRAGService() async {
    _ragScoringService = RAGScoringService(
      openaiApiKey: dotenv.env['OPENAI_API_KEY']!,
    );
    await _ragScoringService.initializeVectorStore(_problems);
  }

  Future<void> _showPreviewDialog(Uint8List imageBytes) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('画像プレビュー'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(imageBytes),
              const SizedBox(height: 16),
              const Text('この画像を送信しますか？'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('送信'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _sendToMathpix(imageBytes);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendToMathpix(Uint8List imageBytes) async {
    setState(() {
      _isProcessing = true;
      _recognizedText = '認識中...';
      _rawResponse = '';
    });

    try {
      // Mathpixのレスポンスを取得
      final response = await recognizeMathpixWithRaw(imageBytes);
      setState(() {
        _recognizedText = response['result'] ?? '';
        _rawResponse = response['raw'] ?? '';
        _isProcessing = false;
      });
      if (_recognizedText.startsWith('エラー') || _recognizedText.startsWith('認識エラー')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_recognizedText)),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _recognizedText = 'エラーが発生しました';
        _rawResponse = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Future<void> _recognizeText() async {
    if (_isProcessing) return;
    try {
      final Uint8List? pngBytes = await _controller.toPngBytes();
      if (pngBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像の生成に失敗しました')),
        );
        return;
      }
      // 余白を追加
      final paddedBytes = await addPaddingToImage(pngBytes);
      await _sendToMathpix(paddedBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Future<void> _gradeWithAI() async {
    final problemLatex = _problems[_currentProblemIndex]['latex'] ?? '';
    final answerLatex = normalize_to_latex(_recognizedText);

    setState(() {
      _aiResult = 'AI採点中...';
      _aiRawResponse = '';
    });

    try {
      final result = await _ragScoringService.scoreAnswer(
        problemLatex: problemLatex,
        answerLatex: answerLatex,
      );

      setState(() {
        _aiResult = result['detailed_feedback'];
        _aiRawResponse = jsonEncode(result);
      });

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AIResultScreen(
            result: _aiResult,
            rawResponse: _aiRawResponse,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _aiResult = 'AI採点エラー: $e';
        _aiRawResponse = '';
      });
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
            width: double.infinity,
            color: Colors.purple.shade50,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '問題:  ${_problems[_currentProblemIndex]['display']}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _nextProblem,
                  child: const Text('次の問題'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Column(
              children: [
                Text(
                  '数式認識のコツ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• 数式は大きく・はっきりと書いてください\n'
                  '• 文字間のスペースを適切に取りましょう\n'
                  '• 分数や指数は特に大きく書いてください\n'
                  '• 複雑な数式は分割して認識すると精度が上がります',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _controller.clear,
                  icon: const Icon(Icons.delete),
                  label: const Text('クリア'),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _recognizeText,
                  icon: const Icon(Icons.search),
                  label: const Text('認識開始'),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '認識結果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _recognizedText.isEmpty ? '認識結果がここに表示されます' : _recognizedText,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _recognizedText.isEmpty ? null : _gradeWithAI,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('AIで採点'),
                ),
                const SizedBox(height: 16),
                if (_aiResult.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _aiResult,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ),
                const SizedBox(height: 16),
                // const Text(
                //   'デバッグ用レスポンス',
                //   style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                // ),
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Text(
                //     _rawResponse,
                //     style: const TextStyle(fontSize: 12, color: Colors.grey),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
