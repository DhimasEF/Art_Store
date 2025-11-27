import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard_admin.dart';
import 'dashboard_creator.dart';
import 'dashboard_user.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String message = '';

  Future<void> login() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await ApiService.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      if (result['status'] == true && result['user'] != null) {
        final user = result['user'];
        final role = user['role'] ?? 'user'; // default role

        // ✅ Simpan ke local storage
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token'] ?? '');
        await prefs.setInt('id_user', int.parse(user['id_user'].toString()));
        await prefs.setString('username', user['username'] ?? '');
        await prefs.setString('email', user['email'] ?? '');
        await prefs.setString('role', role);
        await prefs.setBool('need_refresh', true);

        // ✅ Navigasi berdasarkan role
        Widget nextPage;
        switch (role) {
          case 'admin':
            nextPage = AdminDashboardPage();
            break;
          case 'creator':
            nextPage = CreatorDashboardPage();
            break;
          default:
            nextPage = UserDashboardPage();
        }
  
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextPage),
        );
      } else {
        setState(() {
          message = result['message'] ?? 'Login gagal';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Terjadi kesalahan: $e';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masuk ke akun kamu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: login,
                      child: const Text('Login'),
                    ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterPage()),
                ),
                child: const Text('Belum punya akun? Register'),
              ),
            ),
            if (message.isNotEmpty)
              Center(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
