import 'package:flutter/material.dart';
import 'package:context_app/features/home/screens/home_screen.dart';
import 'package:context_app/features/passport/screens/passport_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    PassportScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Passport'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF137fec),
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF101922),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
