import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';

class SeriyaApp extends StatelessWidget {
  const SeriyaApp({super.key});

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
      ),
      home: const DashboardScreen(),
    );
  }
}
