import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.instance.initialize();
  runApp(const ProviderScope(child: EduVizApp()));
}

class EduVizApp extends StatelessWidget {
  const EduVizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduViz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF4F7F1),
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
