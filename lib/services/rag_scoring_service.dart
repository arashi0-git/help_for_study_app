import 'vector_store.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RAGScoringService {
  final VectorStore _vectorStore;
  final String _apiKey;
  
  RAGScoringService({
    required String openaiApiKey,
  }) : _apiKey = openaiApiKey,
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
    for (var problem in problems) {
      final embedding = await fetchEmbedding(problem['latex']!);
      await _vectorStore.addVector(
        id: problem['display']!,
        vector: embedding,
        metadata: problem,
      );
    }
  }

  Future<Map<String, dynamic>> scoreAnswer({
    required String problemLatex,
    required String answerLatex,
  }) async {
    // 問題のベクトルを取得
    final problemEmbedding = await fetchEmbedding(problemLatex);
    final similarProblems = await _vectorStore.searchSimilar(
      vector: problemEmbedding,
      limit: 3,
    );

    // 解答のベクトルを取得
    final answerEmbedding = await fetchEmbedding(answerLatex);
    
    // 類似度スコアを計算
    double similarityScore = 0;
    for (var problem in similarProblems) {
      final problemVector = await _vectorStore.getVector(problem['id'] as String);
      if (problemVector != null) {
        similarityScore += _vectorStore.cosineSimilarity(answerEmbedding, problemVector);
      }
    }
    similarityScore /= similarProblems.length;

    // GPT-4を使用して詳細な採点を実行
    final prompt = '''
    以下の問題と解答を採点してください。
    ただし、数式は LaTeX ではなく、通常の記号形式（例:3x² - 7x + 2 + 5x  など）で表記してください。  
    途中式や変形もすべてこの形式で書いてください。。
    
    問題: $problemLatex
    解答: $answerLatex
    
    類似度スコア: ${similarityScore.toStringAsFixed(2)}
    
    与えられた問題に対して、解答が正しいかどうかを判断してください。
    正しい場合は、正解として採点してください。
    間違っている場合は、間違っている部分を指摘してください。
    数式はUnicodeで出力してください。
    ''';

    final response = await fetchChatCompletion(_apiKey, prompt);

    return {
      'score': similarityScore,
      'detailed_feedback': response,
    };
  }

  Future<String> fetchChatCompletion(String apiKey, String prompt) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': 'あなたは数学の採点者です。'},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 256,
      }),
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      final decoded = utf8.decode(response.bodyBytes);
      throw Exception('ChatCompletion取得失敗: $decoded');
    }
  }
} 