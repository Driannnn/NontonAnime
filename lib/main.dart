import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'firebase_options.dart';

// ⚠️ Web-specific import untuk URL strategy
// Conditional import: hanya di-compile untuk web
import 'package:flutter_web_plugins/flutter_web_plugins.dart'
    if (dart.library.io) 'utils/stub_url_strategy.dart';

late GoRouter router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ PENTING: Set URL strategy SEBELUM Firebase initialization
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize Firebase (SETELAH URL strategy diset)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize router
  router = appRouter;

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
      routerConfig: router);
  }
}
