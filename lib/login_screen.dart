// @file       login_screen.dart
// @copyright  Copyright (C) 2025 HAQ. All rights reserved.
// @license    This project is released under the <Your_License> License.
// @version    major.minor.patch
// @date       2025-10-9
// @author     Hai Tran
// @author     Hung Le
// @author     Khang Le
// @brief      Implements the login UI and authentication logic.
// ============================== Imports ==============================
import 'package:flutter/material.dart';
import 'garden_manager.dart';

// ============================= Constants =============================
const hardUsername = "haq";
const hardPassword = "1";

// ============================ Global Functions =======================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

// ========================== Local Functions ==========================
  void _login() {
    if (_usernameController.text == hardUsername &&
        _passwordController.text == hardPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GardenScreen()),
      );
    } else {
      setState(() {
        _errorMessage = "Sai username hoặc password!";
      });
    }
  }

// =========================== Main Widget =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Đăng nhập",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: const Text("Login")),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================ End of File ============================