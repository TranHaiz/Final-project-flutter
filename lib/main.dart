// Điểm khởi đầu ứng dụng, điều hướng vào màn hình login
import 'package:flutter/material.dart';
import 'logic_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Garden',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(), // mở login trước
    );
  }
}
