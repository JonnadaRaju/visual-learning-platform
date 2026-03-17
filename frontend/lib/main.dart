import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'screens/class_selection_screen.dart';
import 'screens/home_screen.dart';

void main() async {
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
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF378ADD),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F0F18),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F18),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F18),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white70),
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white54),
          labelLarge: TextStyle(color: Colors.white60),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          elevation: 0,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF378ADD),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
          thumbColor: const Color(0xFF378ADD),
          overlayColor: const Color(0xFF378ADD).withValues(alpha: 0.15),
          trackHeight: 3,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? const Color(0xFF378ADD)
                  : Colors.white38),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? const Color(0xFF378ADD).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF378ADD),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF378ADD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1A1A24),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: AppConfig.instance.selectedClass != null
          ? const HomeScreen()
          : const ClassSelectionScreen(),
    );
  }
}