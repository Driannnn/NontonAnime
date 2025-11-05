import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  runApp(const AnimeApp());
}

class AnimeApp extends StatelessWidget {
  const AnimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Anime Pastel',
      debugShowCheckedModeBanner: false,
      theme: buildPastelTheme(),
      routerConfig: appRouter,
    );
  }
}
