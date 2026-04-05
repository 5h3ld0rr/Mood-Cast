import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:convert';
import '../main.dart';
import '../theme.dart';
import '../screens/notifications/notification_details.dart';
import 'mood_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification History
  final List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  void clearHistory() {
    _history.clear();
  }

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'MoodCast Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  void markAsRead(String id) {
    final index = _history.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _history[index]['isRead'] = true;
    }
  }

  void markAllAsRead() {
    for (var n in _history) {
      n['isRead'] = true;
    }
  }

  Future<void> initialize() async {
    // 1. Request FCM Permission (Required for iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM Permisson Granted');
    }

    // 2. Request Local Notification Permission (Android 13+)
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }

    // Initialize local notifications config
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
    );

    // Create Android Notification Channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // Get the token
    String? token = await _fcm.getToken();
    debugPrint("FCM Token: $token");

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        showSimpleNotification(
          title: notification.title ?? "New Message",
          body: notification.body ?? "",
          payload: jsonEncode({
            'title': notification.title,
            'body': notification.body,
            'data': message.data,
          }),
        );
      }
    });
  }

  void _handleNotificationClick(String? payload) {
    if (payload != null && navigatorKey.currentState != null) {
      try {
        final data = jsonDecode(payload);
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => NotificationDetailsScreen(
              title: data['title'] ?? 'Notification',
              body: data['body'] ?? '',
              payload: data['data']?.toString(),
              timestamp: DateTime.now(),
            ),
          ),
        );
      } catch (e) {
        debugPrint("Error parsing notification payload: $e");
      }
    }
  }

  // Method to show a local notification with custom content
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Add to history
    Map<String, dynamic> notificationData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now(),
      'isRead': false,
    };

    if (payload != null) {
      try {
        final decoded = jsonDecode(payload);
        notificationData['data'] = decoded['data'];
      } catch (e) {
        notificationData['data'] = payload;
      }
    }
    _history.add(notificationData);

    // Notify listeners if you have any, or simple setState in screens
    // For now we just update the list.

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'MoodCast Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          color: AppTheme.moodColors[MoodService().currentMood.value] ??
              AppTheme.primary, // Dynamic mood color
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            body,
          ), // Use the body for big text
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload ?? jsonEncode({'title': title, 'body': body}),
    );
  }

  // Handle messages when app is in background or terminated
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    debugPrint("Handling a background message: ${message.messageId}");
  }
}
