import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'models/contact.dart';
import 'providers/contact_provider.dart';
import 'providers/price_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/account_book_screen.dart';
import 'screens/game_table_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await Hive.initFlutter();
  Hive.registerAdapter(ContactAdapter());
  await Hive.openBox('prices');
  await Hive.openBox<Contact>('contacts');
  await Hive.openBox('credits');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'مدیریت گیم نت بزرگا',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF23272E),
        primaryColor: const Color(0xFF1976D2),
        cardColor: const Color(0xFF2C313A),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF2C313A)),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1976D2),
          secondary: Color(0xFF43A047),
          error: Color(0xFFE53935),
          surface: Color(0xFF2C313A),
          onPrimary: Color(0xFFECEFF1),
          onSecondary: Color(0xFFECEFF1),
          onError: Color(0xFFECEFF1),
          onSurface: Color(0xFFECEFF1),
        ),
        textTheme: GoogleFonts.vazirmatnTextTheme(textTheme).apply(
          bodyColor: const Color(0xFFECEFF1),
          displayColor: const Color(0xFFECEFF1),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: const Color(0xFFECEFF1),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFECEFF1),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF1976D2),
          unselectedLabelColor: Color(0xFFECEFF1),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    if (timerProvider.hasActiveTimers) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('خروج از برنامه'),
          content:
              const Text('تایمرهای فعال در حال اجرا هستند. آیا از خروج مطمئن هستید؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('خیر'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('بله'),
            ),
          ],
        ),
      );
      if (result == true) {
        await windowManager.destroy();
      }
    } else {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت گیم نت بزرگا'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'میز بازی'),
              Tab(text: 'دفتر حساب'),
              Tab(text: 'تنظیمات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GameTableScreen(),
            AccountBookScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
    );
  }
}
