import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/places/screens/explore_screen.dart';
import 'package:context_app/features/passport/screens/passport_screen.dart';
import 'package:context_app/features/settings/presentation/screens/settings_screen.dart';

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
    SettingsScreen(),
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
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'bottom_nav.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: 'bottom_nav.passport'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'bottom_nav.profile'.tr(),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF137fec),
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF101922),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
