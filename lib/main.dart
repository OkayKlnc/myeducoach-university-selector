import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  final isLoggedIn = html.window.localStorage['isLoggedIn'] == 'true';
  runApp(MyeducoachApp(isLoggedIn: isLoggedIn));
}

class MyeducoachApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyeducoachApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myeducoach — Üniversite Seçici',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A6E)),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
