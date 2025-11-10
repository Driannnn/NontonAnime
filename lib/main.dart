import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sizer/sizer.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';

// ⚠️ Web-specific import untuk URL strategy
// Conditional import: hanya di-compile untuk web
import 'package:flutter_web_plugins/flutter_web_plugins.dart'
    if (dart.library.io) 'utils/stub_url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Conditional: hanya set URL strategy di web platform
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  runApp(const AnimeApp());
}

class AnimeApp extends StatelessWidget {
  const AnimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp.router(
          title: 'Anime Pastel',
          debugShowCheckedModeBanner: false,
          theme: buildPastelTheme(),
          routerConfig: appRouter,
        );
      },
    );
  }
}
