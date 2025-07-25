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
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF1a1a1a),
          cardColor: const Color(0xFF2c2c2c),
          fontFamily: 'Vazirmatn',
          colorScheme: const ColorScheme.dark().copyWith(
            primary: Colors.blue,
            secondary: Colors.green,
            error: Colors.red,
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fa'), // Farsi
        ],
        locale: const Locale('fa'),
        home: const HomeScreen(),
      ),
    );
  }
}
