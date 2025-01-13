import 'package:flutter/material.dart';
import 'Screen/home_screen.dart'; // تأكد من استيراد ملف home_screen.dart

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robo Manager for Clients',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // تحديد HomeScreen كصفحة البداية
      debugShowCheckedModeBanner: false,
    );
  }
}
