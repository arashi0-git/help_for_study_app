class Problem {
  final String id;
  final String question;
  final String answer;
  final DateTime createdAt;
  final String? imageUrl;

  Problem({
    required this.id,
    required this.question,
    required this.answer,
    required this.createdAt,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory Problem.fromMap(Map<String, dynamic> map) {
    return Problem(
      id: map['id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      imageUrl: map['imageUrl'] as String?,
    );
  }
} 