import 'package:flutter/material.dart';

import 'screens/auth/sign_in_screen.dart';
import 'services/auth_service.dart';

class SeriyaApp extends StatelessWidget {
  const SeriyaApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F9D8B);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seriya',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F8F7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDDE6E3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDDE6E3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: seed, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE85D4A)),
          ),
        ),
      ),
      home: SignInScreen(authService: authService ?? FirebaseAuthService()),
    );
  }
}
