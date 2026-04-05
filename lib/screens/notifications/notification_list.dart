import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
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
      backgroundColor: Theme.of(context).canvasColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Glassmorphic App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).canvasColor.withValues(alpha: 0.8),
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: const Text(
                    'Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  background: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).primaryColor.withValues(
                                  alpha: 0.08,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (notifications.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  onPressed: () => _showClearConfirmation(context),
                ),
            ],
          ),

          // Notification Content
          if (notifications.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).primaryColor.withValues(
                              alpha: 0.05,
                            ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quiet for now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your latest updates will appear here.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final notification =
                      notifications[notifications.length - 1 - index];
                  return _NotificationTile(
                    notification: notification,
                    timeAgo: _getTimeAgo(
                      notification['timestamp'] ?? DateTime.now(),
                    ),
                    onTap: () => _openDetails(context, notification),
                  );
                }, childCount: notifications.length),
              ),
            ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear All?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently remove your activity history.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => NotificationService().clearHistory());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, Map<String, dynamic> notification) {
    NotificationService().markAsRead(notification['id']);
    setState(() {});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailsScreen(
          id: notification['id'],
          title: notification['title'] ?? '',
          body: notification['body'] ?? '',
          payload: notification['data']?.toString(),
          timestamp: notification['timestamp'] ?? DateTime.now(),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'] ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRead
                ? Colors.white.withValues(alpha: 0.05)
                : Theme.of(context).primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRead
                    ? Colors.white.withValues(alpha: 0.05)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIconForTitle(notification['title'] ?? ''),
                color: isRead ? Colors.white24 : Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? '',
                          style: TextStyle(
                            color: isRead ? Colors.white54 : Colors.white,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['body'] ?? '',
                    style: TextStyle(
                      color: isRead ? Colors.white24 : Colors.white70,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
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
