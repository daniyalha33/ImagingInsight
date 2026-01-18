// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'websocket_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Listen to WebSocket notifications
      _listenToWebSocketNotifications();

      _isInitialized = true;
      debugPrint('NotificationService: Initialized');
    } catch (e) {
      debugPrint('NotificationService: Error initializing: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _listenToWebSocketNotifications() {
    final ws = WebSocketService();
    
    // Listen for new notifications from WebSocket
    ws.on('notification:new', (data) {
      debugPrint('NotificationService: WebSocket notification: $data');
      _showLocalNotification(
        title: data['title'] ?? 'New notification',
        body: data['body'] ?? '',
        payload: data,
      );
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('NotificationService: Notification tapped: ${response.payload}');
    
    if (response.payload != null && onNotificationTap != null) {
      // Parse payload (it's stored as chatId)
      try {
        onNotificationTap!({'chatId': response.payload});
      } catch (e) {
        debugPrint('NotificationService: Error parsing payload: $e');
      }
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload?['chatId']?.toString(),
    );
  }

  // Show notification for new message
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await _showLocalNotification(
      title: 'New message from $senderName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      payload: {'chatId': chatId, 'type': 'chat'},
    );
  }

  // Show notification for new test
  Future<void> showTestNotification({
    required String testName,
    required String className,
    String? testId,
  }) async {
    await _showLocalNotification(
      title: 'New Test: $testName',
      body: 'A new test has been assigned in $className',
      payload: {'testId': testId, 'type': 'test'},
    );
  }

  // Show notification for grade
  Future<void> showGradeNotification({
    required String testName,
    required String grade,
    String? testId,
  }) async {
    await _showLocalNotification(
      title: 'Test Graded: $testName',
      body: 'You scored $grade',
      payload: {'testId': testId, 'type': 'grade'},
    );
  }

  // Show custom notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
  }

  // Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _localNotifications.pendingNotificationRequests();
    return pending.length;
  }
}