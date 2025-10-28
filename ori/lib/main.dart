import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'features/home_page.dart';

void main() {
  runApp(const AnimeApp());
}

class AnimeApp extends StatelessWidget {
  const AnimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Pastel',
      debugShowCheckedModeBanner: false,
      theme: buildPastelTheme(),
      home: const HomePage(),
    );
  }
}
