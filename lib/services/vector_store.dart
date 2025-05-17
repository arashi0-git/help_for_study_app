import 'dart:math';

class VectorStore {
  List<Map<String, dynamic>> _vectors = [];

  void clear() {
    _vectors.clear();
  }

  void add(Map<String, dynamic> vector) {
    _vectors.add(vector);
  }

  List<Map<String, dynamic>> get vectors => _vectors;

  Future<List<Map<String, dynamic>>> searchSimilar({
    required List<double> vector,
    required int limit,
  }) async {
    // 簡易的な実装：すべてのベクトルを返す
    return _vectors.take(limit).toList();
  }

  Future<List<double>?> getVector(String id) async {
    // 簡易的な実装：最初のベクトルを返す
    if (_vectors.isNotEmpty) {
      return List<double>.from(_vectors[0]['vector'] ?? []);
    }
    return null;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw Exception('ベクトルの次元が一致しません');
    }

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) {
      return 0;
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
} 