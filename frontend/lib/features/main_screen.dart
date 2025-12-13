import 'package:flutter/material.dart';
import 'package:context_app/features/places/screens/explore_screen.dart';
import 'package:context_app/features/passport/screens/passport_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  static const List<Widget> _widgetOptions = <Widget>[
    ExploreScreen(),
    PassportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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
