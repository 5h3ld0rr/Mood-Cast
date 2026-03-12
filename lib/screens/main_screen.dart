import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'home/home.dart';
import 'scan/analysis.dart';
import 'profile/profile.dart';
import 'search/search.dart';
import 'library/library.dart';
import '../widgets/tab_navigator.dart';
import '../widgets/mini_player.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAnalysisActivated = false;
  final ValueNotifier<bool> _isScanActiveNotifier = ValueNotifier<bool>(false);

  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
    3: GlobalKey<NavigatorState>(),
    4: GlobalKey<NavigatorState>(),
  };

  List<Widget> get _screens => [
    TabNavigator(
      navigatorKey: _navigatorKeys[0]!,
      rootScreen: const HomeScreen(),
    ),
    TabNavigator(
      navigatorKey: _navigatorKeys[1]!,
      rootScreen: const SearchScreen(),
    ),
    _isAnalysisActivated
        ? TabNavigator(
            navigatorKey: _navigatorKeys[2]!,
            rootScreen: AnalysisScreen(activeNotifier: _isScanActiveNotifier),
          )
        : const SizedBox.shrink(),
    TabNavigator(
      navigatorKey: _navigatorKeys[3]!,
      rootScreen: const LibraryScreen(),
    ),
    TabNavigator(
      navigatorKey: _navigatorKeys[4]!,
      rootScreen: const ProfileScreen(),
    ),
  ];

  @override
  void dispose() {
    _isScanActiveNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;

          // Check if current tab navigator can pop
          final currentNavigator = _navigatorKeys[_currentIndex]?.currentState;
          if (currentNavigator != null && await currentNavigator.maybePop()) {
            return;
          }

          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
              _isScanActiveNotifier.value = false;
            });
          } else {
            // If on home tab and can't pop anymore, minimize app
            await SystemNavigator.pop();
          }
        },
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    _isScanActiveNotifier.value = (index == 2);
                    if (index == 2) {
                      _isAnalysisActivated = true;
                    }
                  });
                },
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppTheme.textMuted,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0, top: 8.0),
                      child: Icon(Icons.home, size: 28),
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0, top: 8.0),
                      child: Icon(Icons.search, size: 28),
                    ),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0, top: 8.0),
                      child: Icon(Icons.auto_awesome, size: 28),
                    ),
                    label: 'MoodSync',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0, top: 8.0),
                      child: Icon(Icons.library_music, size: 28),
                    ),
                    label: 'Library',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0, top: 8.0),
                      child: Icon(Icons.person, size: 28),
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
