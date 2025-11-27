import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CI3 JWT Demo',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
