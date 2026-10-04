import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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
      bottomNavigationBar: M3ENavigationBar(
        destinations: const [
          M3ENavigationBarDestination(icon: Icon(Icons.home), label: 'Home'),
          M3ENavigationBarDestination(
            icon: Icon(Icons.list_alt),
            label: 'Transaksi',
          ),
          M3ENavigationBarDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Utang',
          ),
          M3ENavigationBarDestination(
            icon: Icon(Icons.settings),
            label: 'Atur',
          ),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
      ),
    );
  }
}
