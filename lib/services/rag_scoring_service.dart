import 'vector_store.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

class RAGScoringService {
  final VectorStore _vectorStore;
  final String _apiKey;
  final String _backendUrl;
  
  RAGScoringService({
    required String openaiApiKey,
    String backendUrl = 'http://localhost:8000',
  }) : _apiKey = openaiApiKey,
       _backendUrl = backendUrl,
       _vectorStore = VectorStore();

  Future<List<double>> fetchEmbedding(String text) async {
    final url = Uri.parse('https://api.openai.com/v1/embeddings');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'text-embedding-ada-002',
        'input': text,
      }),
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      return List<double>.from(data['data'][0]['embedding']);
    } else {
      final decoded = utf8.decode(response.bodyBytes);
      throw Exception('Embedding取得失敗: $decoded');
    }
  }

  Future<void> initializeVectorStore(List<Map<String, String>> problems) async {
    _vectorStore.clear();
    
    // 問題リストをベクトルストアに追加
    for (var problem in problems) {
      _vectorStore.add({
        'text': problem['latex'] ?? '',
        'type': 'problem',
        'display': problem['display'] ?? '',
      });
    }

    // サンプル解答を読み込む
    try {
      final String sampleAnswers = await rootBundle.loadString('assets/sample_answers.txt');
      final List<String> lines = sampleAnswers.split('\n');
      
      String currentProblem = '';
      String currentAnswer = '';
      String currentExplanation = '';
      
      for (String line in lines) {
        if (line.startsWith('問題:')) {
          if (currentProblem.isNotEmpty) {
            _vectorStore.add({
              'text': currentProblem,
              'answer': currentAnswer,
              'explanation': currentExplanation,
              'type': 'sample',
            });
          }
          currentProblem = line.replaceFirst('問題:', '').trim();
          currentAnswer = '';
          currentExplanation = '';
        } else if (line.startsWith('解答例1:')) {
          currentAnswer = line.replaceFirst('解答例1:', '').trim();
        } else if (line.startsWith('解説:')) {
          currentExplanation = line.replaceFirst('解説:', '').trim();
        }
      }
      
      // 最後の問題を追加
      if (currentProblem.isNotEmpty) {
        _vectorStore.add({
          'text': currentProblem,
          'answer': currentAnswer,
          'explanation': currentExplanation,
          'type': 'sample',
        });
      }
    } catch (e) {
      print('サンプル解答の読み込みエラー: $e');
    }
  }

  Future<Map<String, dynamic>> scoreAnswer({
    required String problemLatex,
    required String answerLatex,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/score'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'problem': problemLatex,
          'answer': answerLatex,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);
        return {
          'detailed_feedback': data['feedback'],
          'raw_response': decoded,
        };
      } else {
        throw Exception('APIリクエストエラー: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('採点エラー: $e');
    }
  }

  Future<double> _calculateSimilarity(String text1, String text2) async {
    // 簡易的な類似度計算（実際のプロジェクトでは、より高度なベクトル類似度計算を使用することを推奨）
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/embeddings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'text-embedding-ada-002',
        'input': [text1, text2],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final embedding1 = data['data'][0]['embedding'];
      final embedding2 = data['data'][1]['embedding'];
      
      // コサイン類似度を計算
      double dotProduct = 0;
      double norm1 = 0;
      double norm2 = 0;
      
      for (int i = 0; i < embedding1.length; i++) {
        dotProduct += embedding1[i] * embedding2[i];
        norm1 += embedding1[i] * embedding1[i];
        norm2 += embedding2[i] * embedding2[i];
      }
      
      return dotProduct / (sqrt(norm1) * sqrt(norm2));
    } else {
      throw Exception('Embedding APIリクエストエラー: ${response.statusCode}');
    }
  }

  /// sample_answerのデータベースを参考に新しい問題を自動生成する
  Future<Map<String, String>> generateNewProblem() async {
    // 例題データベースから例題を抽出
    final List<Map<String, dynamic>> samples = _vectorStore.vectors.where((v) => v['type'] == 'sample').toList();
    if (samples.isEmpty) {
      throw Exception('サンプルデータがありません');
    }
    // 例題をプロンプト用に整形
    String examples = samples.take(5).map((e) =>
      '問題: ${e['text']}\n解答例1: ${e['answer']}\n解説: ${e['explanation']}'
    ).join('\n---\n');

    String prompt = '''
以下は数学の例題データベースです。---で区切られています。
---
$examples
---
このデータベースを参考に、同じ形式・難易度の新しい問題を1問作成してください。出力は必ず以下の形式で:
問題: ...\n解答例1: ...\n解説: ...
''';

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'あなたは数学の先生です。'},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 256,
        'temperature': 0.8,
      }),
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      final content = data['choices'][0]['message']['content'] as String;
      // 出力をパース
      final problemMatch = RegExp(r'問題[:：](.*)').firstMatch(content);
      final answerMatch = RegExp(r'解答例1[:：](.*)').firstMatch(content);
      final explanationMatch = RegExp(r'解説[:：](.*)').firstMatch(content);
      if (problemMatch != null && answerMatch != null && explanationMatch != null) {
        return {
          'problem': problemMatch.group(1)!.trim(),
          'answer': answerMatch.group(1)!.trim(),
          'explanation': explanationMatch.group(1)!.trim(),
        };
      } else {
        throw Exception('AIの出力形式が不正です: $content');
      }
    } else {
      throw Exception('OpenAI APIエラー: ${response.statusCode} ${response.body}');
    }
  }
} 

Future<void> saveGeneratedProblem(Map<String, String> problem) async {
  final response = await http.post(
    Uri.parse('http://localhost:8000/save_example'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'problem': problem['problem'],
      'answer': problem['answer'],
      'explanation': problem['explanation'],
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('保存失敗: ${response.body}');
  }
}
