import 'dart:math';

class VectorStore {
  final Map<String, List<double>> _vectors = {};
  final Map<String, Map<String, dynamic>> _metadata = {};

  Future<void> addVector({
    required String id,
    required List<double> vector,
    Map<String, dynamic>? metadata,
  }) async {
    _vectors[id] = vector;
    if (metadata != null) {
      _metadata[id] = metadata;
    }
  }

  Future<List<Map<String, dynamic>>> searchSimilar({
    required List<double> vector,
    required int limit,
  }) async {
    final scores = _vectors.entries.map((entry) {
      final similarity = cosineSimilarity(vector, entry.value);
      return {
        'id': entry.key,
        'score': similarity,
        'metadata': _metadata[entry.key],
      };
    }).toList();

    scores.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return scores.take(limit).toList();
  }

  Future<List<double>?> getVector(String id) async {
    return _vectors[id];
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
} 