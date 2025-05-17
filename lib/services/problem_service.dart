import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/problem.dart';

class ProblemService {
  final CollectionReference _problemsCollection =
      FirebaseFirestore.instance.collection('problems');

  // 問題を保存する
  Future<void> saveProblem(Problem problem) async {
    await _problemsCollection.doc(problem.id).set(problem.toMap());
  }

  // 問題を取得する
  Future<Problem?> getProblem(String id) async {
    final doc = await _problemsCollection.doc(id).get();
    if (doc.exists) {
      return Problem.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // 全ての問題を取得する
  Stream<List<Problem>> getProblems() {
    return _problemsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Problem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // 問題を削除する
  Future<void> deleteProblem(String id) async {
    await _problemsCollection.doc(id).delete();
  }
} 