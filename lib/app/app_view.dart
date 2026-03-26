import 'package:flutter/material.dart';
import 'package:niceleep/app/constant.dart';
import 'package:niceleep/settings/state_mgmt/theme_cntlr.dart';
import 'package:provider/provider.dart';
import 'package:niceleep/app/state_mgmt/sound_manager.dart';
import 'package:niceleep/timed_off/timed_off_page_view.dart';
import 'package:niceleep/home/home_page.dart';
import 'package:niceleep/settings/settings_page_view.dart';

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  @override
  void dispose() {
    SoundManager.i.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SoundManager.i),
        ChangeNotifierProvider.value(value: ThemeCntlr.i),
      ],
      child: Consumer<ThemeCntlr>(
        builder: (context, themeCntlr, child) {
          return MaterialApp(
            title: Constant.appName,
            theme: themeCntlr.lightTheme,
            darkTheme: themeCntlr.darkTheme,
            themeMode: themeCntlr.themeMode,
            home: const MainPage(),
          );
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const HomePage(),
    const TimedOffPageView(),
    const SettingsPageView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.my_library_music_outlined),
            selectedIcon: Icon(Icons.my_library_music),
            label: '声音',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: '定时关闭',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
