import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/notification_service.dart';
import 'notification_details.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService().history;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                setState(() {
                  if (value == 'clear') {
                    NotificationService().clearHistory();
                  } else if (value == 'read_all') {
                    NotificationService().markAllAsRead();
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Clear all',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'All caught up!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No new notifications at the moment.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                // Show latest first
                final notification =
                    notifications[notifications.length - 1 - index];
                final bool isRead = notification['isRead'] ?? false;
                final DateTime timestamp = notification['timestamp'] is DateTime
                    ? notification['timestamp']
                    : DateTime.now();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      NotificationService().markAsRead(notification['id']);
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailsScreen(
                          id: notification['id'],
                          title: notification['title'] ?? '',
                          body: notification['body'] ?? '',
                          payload: notification['data']?.toString(),
                          timestamp: timestamp,
                        ),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead
                          ? AppTheme.cardBg.withOpacity(0.1)
                          : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRead
                            ? Colors.white.withOpacity(0.03)
                            : AppTheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: isRead
                          ? []
                          : [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Hero(
                              tag: 'notif_icon_${notification['id']}',
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? Colors.white.withOpacity(0.05)
                                      : AppTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  _getIconForTitle(notification['title'] ?? ''),
                                  color: isRead
                                      ? AppTheme.textMuted
                                      : AppTheme.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF080C14),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification['title'] ?? '',
                                      style: TextStyle(
                                        color: isRead
                                            ? Colors.white70
                                            : Colors.white,
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _getTimeAgo(timestamp),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification['body'] ?? '',
                                style: TextStyle(
                                  color: isRead
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('music') || t.contains('song') || t.contains('playlist')) {
      return Icons.headset;
    } else if (t.contains('account') ||
        t.contains('profile') ||
        t.contains('verify')) {
      return Icons.person;
    } else if (t.contains('subscription') ||
        t.contains('plan') ||
        t.contains('payment')) {
      return Icons.star_rounded;
    } else if (t.contains('analysis') ||
        t.contains('mood') ||
        t.contains('scan')) {
      return Icons.psychology;
    }
    return Icons.notifications_active;
  }
}
