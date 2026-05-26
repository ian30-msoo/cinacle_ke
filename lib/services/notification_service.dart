import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

/// Call NotificationService.instance.init() from main.dart after Firebase.initializeApp().
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'cenacle_messages';
  static const _channelName = 'Messages';
  static const _channelDesc = 'Incoming message notifications';

  Future<void> init() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setting up local notifications channel (Android)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    //  local notifications plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(initSettings);

    // Saving FCM token to Firestore
    final token = await _fcm.getToken();
    if (token != null) await ChatService().saveFcmToken(token);

    // Refreshing token if it rotates
    _fcm.onTokenRefresh.listen((newToken) async {
      await ChatService().saveFcmToken(newToken);
    });

    // show local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // app opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // app launched from terminated state via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['conversationId'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint(
        'Notification tapped: conversationId=${message.data['conversationId']}');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}
