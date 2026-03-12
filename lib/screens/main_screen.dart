import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'home/home.dart';
import 'scan/analysis.dart';
import 'profile/profile.dart';
import 'search/search.dart';
import 'library/library.dart';
import 'community/community.dart';
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
    5: GlobalKey<NavigatorState>(),
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
      rootScreen: const CommunityScreen(),
    ),
    TabNavigator(
      navigatorKey: _navigatorKeys[5]!,
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
            NavigationBarTheme(
              data: NavigationBarThemeData(
                indicatorColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.15),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    );
                  }
                  return const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(
                      color: Theme.of(context).primaryColor,
                      size: 26,
                    );
                  }
                  return const IconThemeData(
                    color: AppTheme.textMuted,
                    size: 26,
                  );
                }),
              ),
              child: Container(
                margin: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: 16,
                  top: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _currentIndex = index;
                          _isScanActiveNotifier.value = (index == 2);
                          if (index == 2) {
                            _isAnalysisActivated = true;
                          }
                        });
                      },
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      height: 65,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.search_outlined),
                          selectedIcon: Icon(Icons.search),
                          label: 'Search',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.theater_comedy_outlined),
                          selectedIcon: Icon(Icons.theater_comedy),
                          label: 'MoodSync',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.library_music_outlined),
                          selectedIcon: Icon(Icons.library_music),
                          label: 'Library',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.groups_outlined),
                          selectedIcon: Icon(Icons.groups),
                          label: 'Community',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
