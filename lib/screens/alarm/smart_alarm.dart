import 'package:flutter/material.dart';
import '../../theme.dart';
import '../scan/analysis.dart';

class SmartAlarmScreen extends StatefulWidget {
  const SmartAlarmScreen({super.key});

  @override
  State<SmartAlarmScreen> createState() => _SmartAlarmScreenState();
}

class _SmartAlarmScreenState extends State<SmartAlarmScreen> {
  TimeOfDay _alarmTime = const TimeOfDay(hour: 7, minute: 0);
  bool _isAlarmEnabled = true;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.cardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _alarmTime) {
      setState(() {
        _alarmTime = picked;
      });
    }
  }

  void _simulateAlarm() {
    // Usually an alarm plugin would trigger a background task that launches an intent.
    // For demonstration, we'll route to the Scan screen, treating it as a "Morning Scan".
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(activeNotifier: ValueNotifier(true)),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Alarm triggered! Time for your morning scan.'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Smart Wake-Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      const Text(
                        'Start your day with the perfect vibe based on your morning mood.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 48),

                      // Time Display
                      Center(
                        child: GestureDetector(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.cardBg,
                              border: Border.all(
                                color: _isAlarmEnabled
                                    ? Theme.of(context).primaryColor
                                    : Colors.white12,
                                width: 2,
                              ),
                              boxShadow: _isAlarmEnabled
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  // Format time hr:min AM/PM
                                  '${_alarmTime.hourOfPeriod == 0 ? 12 : _alarmTime.hourOfPeriod}:${_alarmTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: _isAlarmEnabled ? Colors.white : Colors.white54,
                                  ),
                                ),
                                Text(
                                  _alarmTime.period == DayPeriod.am ? 'AM' : 'PM',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: _isAlarmEnabled
                                        ? Theme.of(context).primaryColor
                                        : Colors.white54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Settings
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Alarm Enabled',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'Will ring at the specified time.',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              value: _isAlarmEnabled,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (val) {
                                setState(() {
                                  _isAlarmEnabled = val;
                                });
                              },
                            ),
                            const Divider(color: Colors.white12, height: 1),
                            ListTile(
                              leading: Icon(Icons.face, color: Theme.of(context).primaryColor),
                              title: const Text('Smart Mood Scan', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Scans your face to tailor the first song', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              trailing: Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                            ),
                            const Divider(color: Colors.white12, height: 1),
                            ListTile(
                              leading: Icon(Icons.volume_up, color: Theme.of(context).primaryColor),
                              title: const Text('Gentle Wake', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Volume gradually increases over 5 minutes', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              trailing: Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Simulate Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _simulateAlarm,
                          icon: const Icon(Icons.alarm_on, color: Colors.white),
                          label: const Text(
                            'SIMULATE ALARM NOW',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
