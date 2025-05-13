import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/drawing_screen.dart';
import 'providers/drawing_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DrawingProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DrawingScreen(),
    );
  }
}