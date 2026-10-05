import 'package:material_ui/material_ui.dart';

import 'transaksi_screen.dart';
import 'atur_screen.dart';
import 'home_screen.dart';
import 'utang_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    TransaksiScreen(),
    UtangScreen(),
    AturScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Transaksi'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Utang',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Atur'),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
      ),
    );
  }
}
