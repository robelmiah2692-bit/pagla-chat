import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // ১. পারমিশন রিকোয়েস্ট (অ্যান্ড্রয়েড ১৩+ এর জন্য এটি মাস্ট)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('ইউজার পারমিশন দিয়েছে');
    }

    // ২. টোকেন নেওয়া
    String? token = await _fcm.getToken();
    print("User Device Token: $token");

    // ৩. লোকাল নোটিফিকেশন চ্যানেল সেটআপ
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidSettings);
        
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // নোটিফিকেশনে ক্লিক করলে কি হবে তা এখানে লিখতে পারেন
      },
    );

    // ৪. 🔥 ফরগ্রাউন্ড লিসেনার (অ্যাপ খোলা থাকা অবস্থায় নোটিফিকেশন আসার জন্য)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("মেসেজ পাওয়া গেছে: ${message.notification?.title}");
      if (message.notification != null) {
        display(message);
      }
    });
  }

  // ৫. নোটিফিকেশন দেখানোর ফাংশন (চ্যানেল আইডি ফিক্সড)
  static void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel', // এই আইডিটি মেনিফেস্টের সাথে মিল থাকতে হবে
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
      );

      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification?.title ?? "No Title",
        message.notification?.body ?? "No Body",
        notificationDetails,
      );
    } catch (e) {
      print("Error displaying notification: $e");
    }
  }
}
