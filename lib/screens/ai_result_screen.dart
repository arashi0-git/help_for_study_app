import 'package:flutter/material.dart';

class AIResultScreen extends StatelessWidget {
  final String result;
  final String rawResponse;

  const AIResultScreen({Key? key, required this.result, required this.rawResponse}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI採点結果')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI採点結果', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(result, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            // const Text('AIデバッグ用レスポンス', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  rawResponse,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 