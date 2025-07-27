import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/contact_provider.dart';
import 'providers/price_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
      ],
      child: MaterialApp(
        title: 'مدیریت گیم نت',
        debugShowCheckedModeBanner: false, // Remove debug banner
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fa', ''), // Persian
        ],
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF1976D2), // Material Blue
          scaffoldBackgroundColor: const Color(0xFF23272E), // Dark background
          cardColor: const Color(0xFF2C313A), // Slightly lighter for cards
          colorScheme: const ColorScheme.dark().copyWith(
            primary: const Color(0xFF1976D2), // Material Blue
            secondary: const Color(0xFF43A047), // Material Green
            error: const Color(0xFFE53935), // Material Red
            surface: const Color(0xFF2C313A), // For card/dialog backgrounds
            onSurface: const Color(0xFFECEFF1), // Light text on surface
          ),
          // Text theming (example, can be expanded)
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: Color(0xFFECEFF1)),
            titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Color(0xFFECEFF1)),
            bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFECEFF1)),
            headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFECEFF1)),
          ).apply(
            fontFamily: 'Vazirmatn', // Apply Vazirmatn font globally
          ),
          // AppBar Theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2), // Primary color for AppBar
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 24, fontWeight: FontWeight.bold),
          ),
          // ElevatedButton Theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF1976D2), // Primary color for buttons
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          // TextButton Theme
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1976D2), // Primary color for text buttons
              textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          // Card Theme Data
          cardTheme: CardThemeData(
            color: const Color(0xFF2C313A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 4,
            // Add other properties if needed for CardThemeData
          ),
          // Input Decoration Theme (for TextFields)
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF23272E), // Match background or slightly lighter
            labelStyle: const TextStyle(fontFamily: 'Vazirmatn', color: Color(0xFFECEFF1)),
            hintStyle: const TextStyle(fontFamily: 'Vazirmatn', color: Color(0xFF757575)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF424242)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF424242)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2), // Primary color on focus
            ),
          ),
        ),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: HomeScreen(),
        ),
      ),
    );
  }
}
