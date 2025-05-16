import 'package:flutter/material.dart';
import 'screens/handwriting_recognition_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '手書きOCRデモ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HandwritingRecognitionScreen(),
    );
  }
}
