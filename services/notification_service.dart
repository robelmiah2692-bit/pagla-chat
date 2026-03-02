import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // ইউজারের কাছে অনুমতি চাওয়া
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // টোকেন নেওয়া (এই টোকেন দিয়েই নির্দিষ্ট ইউজারকে মেসেজ পাঠানো হয়)
    String? token = await _fcm.getToken();
    print("User Device Token: $token");

    // নোটিফিকেশন চ্যানেল সেটআপ (অ্যান্ড্রয়েড ৮+ এর জন্য)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
  }

  // লাইভ নোটিফিকেশন দেখানোর ফাংশন
  static void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
      );
    } catch (e) {
      print(e);
    }
  }
}
