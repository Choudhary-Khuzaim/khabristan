import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const KhabarIsTanApp());
}

class KhabarIsTanApp extends StatelessWidget {
  const KhabarIsTanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return AnimatedBuilder(
      animation: themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'KhabarIsTan',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const WelcomeScreen(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F172A), // Slate 900
        primary: const Color(0xFF0F172A),
        secondary: const Color(0xFF334155), // Slate 700
        tertiary: const Color(0xFF0EA5E9), // Sky 500
        surface: const Color(0xFFF8FAFC), // Slate 50
        error: const Color(0xFFEF4444), // Red 500
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
        prefixIconColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.poppins(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.inter(
          color: const Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: const Color(0xFF334155),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          height: 1.5,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF38BDF8), // Sky 400
        primary: const Color(0xFF38BDF8),
        secondary: const Color(0xFF94A3B8), // Slate 400
        tertiary: const Color(0xFF0EA5E9), // Sky 500
        surface: const Color(0xFF0F172A), // Slate 900
        error: const Color(0xFFF87171), // Red 400
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF020617), // Slate 950
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF38BDF8),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B), // Slate 800
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
        prefixIconColor: const Color(0xFF38BDF8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF38BDF8),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(
          color: const Color(0xFFF1F5F9),
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: const Color(0xFFF1F5F9),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.poppins(
          color: const Color(0xFFF1F5F9),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.inter(
          color: const Color(0xFFE2E8F0),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: const Color(0xFFCBD5E1),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          height: 1.5,
        ),
      ),
    );
  }
}
