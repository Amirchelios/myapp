import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import 'game_table_screen.dart';
import 'account_book_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    GameTableScreen(),
    AccountBookScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final bool hasActiveTimers = timerProvider.devices.any((d) => d.isActive) || timerProvider.groups.any((g) => g.isActive);

    if (hasActiveTimers) {
       if (!context.mounted) return false; // Corrected mounted check
      return await showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl, // Ensure RTL for dialog
              child: AlertDialog(
                title: const Text('هشدار'),
                content: const Text('تایمرهای فعال در برنامه وجود دارند. آیا مطمئنید که می‌خواهید خارج شوید؟'),
                actions: [
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
            ),
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت گیم نت'),
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.gamepad),
              label: 'میز بازی',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'دفتر حساب',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'تنظیمات',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
