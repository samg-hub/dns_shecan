import 'package:flutter/material.dart';
import '../theme.dart';
import '../presentation/home/home_screen.dart';

class ShecanApp extends StatelessWidget {
  const ShecanApp({super.key});

  @override
  Widget build(BuildContext context) {
    const materialTheme = MaterialTheme(TextTheme());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shecan DNS',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.system, // Set to light as per user request
      home: const HomeScreen(),
    );
  }
}
