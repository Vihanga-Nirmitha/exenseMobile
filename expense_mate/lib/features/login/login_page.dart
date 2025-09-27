import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Example: backend returns { "token": "xxx", "user": { "id": 1, "email": "..." } }
      final token = response['token'];

      if (token != null) {
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt", token);
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        String? email = decodedToken['sub'];
        if (email != null) {
          await prefs.setString("email", email);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login successful!")),
          );

          // Navigate to GroupsScreen using GoRouter
          context.go('/groups');
        }
      } else {
        throw Exception("No token received");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
