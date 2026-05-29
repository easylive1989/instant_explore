import 'package:context_app/app/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/daily_story/presentation/screens/story_list_screen.dart';
import 'package:context_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:context_app/features/journey/presentation/screens/journey_screen.dart';
import 'package:context_app/features/settings/presentation/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  Locale? _currentLocale;

  static const List<Widget> _widgetOptions = <Widget>[
    StoryListScreen(),
    ExploreScreen(),
    JourneyScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    if (_currentLocale != locale) {
      _currentLocale = locale;
      if (mounted) {
        setState(() {});
      }
    }
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
            icon: const Icon(Icons.auto_stories),
            label: 'bottom_nav.stories'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore),
            label: 'bottom_nav.explore'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: 'bottom_nav.journey'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: 'bottom_nav.settings'.tr(),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
