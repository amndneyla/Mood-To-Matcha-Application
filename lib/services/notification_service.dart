import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
  }

  Future<void> showMatchaNotification(String drinkName) async {
    const androidDetails = AndroidNotificationDetails(
      'matcha_channel',
      'Matcha Notifications',
      channelDescription: 'Notifikasi Mood to Matcha 🍵',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      '🍵 Matcha Siap!',
      'Pesanan $drinkName kamu sedang disiapkan 💚',
      details,
    );
  }
}
