import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_config.dart';
import 'screens/class_selection_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.instance.initialize();
  runApp(const ProviderScope(child: EduVizApp()));
}

class EduVizApp extends StatelessWidget {
  const EduVizApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F0F13);
    const surface = Color(0xFF1A1A24);
    const primaryText = Color(0xFFFFFFFF);
    const secondaryText = Color(0xFFAAAAAA);

    return MaterialApp(
      title: 'EduViz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF42A5F5),
          secondary: Color(0xFFAB47BC),
          surface: surface,
          onPrimary: primaryText,
          onSecondary: primaryText,
          onSurface: primaryText,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData.dark().textTheme.apply(
                bodyColor: primaryText,
                displayColor: primaryText,
              ),
        ).copyWith(
          bodyMedium: const TextStyle(color: secondaryText),
          bodySmall: const TextStyle(color: secondaryText),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: primaryText,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        useMaterial3: true,
      ),
      home: AppConfig.instance.selectedClass == null
          ? const ClassSelectionScreen()
          : const HomeScreen(),
    );
  }
}