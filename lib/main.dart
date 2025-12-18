<<<<<<< HEAD
https://github.com/TranHaiz/Final-project-flutter.gitimport 'dart:convert';
import 'dart:io';
=======
// Điểm khởi đầu ứng dụng, điều hướng vào màn hình login
>>>>>>> faac27e3ec8560b77c20b6111aceedc40a1ee822
import 'package:flutter/material.dart';
import 'login_screen.dart';

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
      debugShowCheckedModeBanner: false,
    );
  }
}
