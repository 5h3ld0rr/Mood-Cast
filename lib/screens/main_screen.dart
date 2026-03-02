import 'package:flutter/material.dart';
import '../theme.dart';
import 'home/home.dart';
import 'scan/analysis.dart';
import 'player.dart';
import 'insights/insights.dart';
import 'profile/profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAnalysisActivated = false;

  List<Widget> get _screens => [
    const HomeScreen(),
    _isAnalysisActivated
        ? AnalysisScreen(isActive: _currentIndex == 1)
        : const SizedBox.shrink(),
    const PlayerScreen(),
    const InsightsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14), // #080c14
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF080C14).withOpacity(0.9),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                if (index == 1) {
                  _isAnalysisActivated = true;
                }
              });
            },
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textMuted,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
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
                  child: Icon(Icons.document_scanner, size: 28),
                ),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0, top: 8.0),
                  child: Icon(Icons.play_circle_fill, size: 28),
                ),
                label: 'Player',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0, top: 8.0),
                  child: Icon(Icons.insights, size: 28),
                ),
                label: 'Insights',
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
      ),
    );
  }
}
