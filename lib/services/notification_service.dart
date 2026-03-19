import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // অ্যান্ড্রয়েডের জন্য হাই ইম্পর্টেন্স চ্যানেল (এটি মেনিফেস্টের সাথে মিল থাকতে হবে)
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // ID
    'High Importance Notifications', // Title
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initNotification() async {
    // ১. পারমিশন রিকোয়েস্ট (অ্যান্ড্রয়েড ১৩+ এর জন্য মাস্ট)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ ইউজার নোটিফিকেশন পারমিশন দিয়েছে');
    }

    // ২. টোকেন নেওয়া (এটি ফায়ারবেস কনসোলে টেস্ট করার জন্য লাগে)
    String? token = await _fcm.getToken();
    print("🚀 User Device Token: $token");

    // ৩. লোকাল নোটিফিকেশন চ্যানেল সেটআপ
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidSettings);
        
    // চ্যানেলটি সিস্টেমে রেজিস্টার করা
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // এখানে ক্লিক করলে কোন পেজে যাবে তা লিখতে পারেন
        print("🔔 নোটিফিকেশনে ক্লিক করা হয়েছে: ${details.payload}");
      },
    );

    // ৪. 🔥 ফরগ্রাউন্ড লিসেনার (অ্যাপ খোলা থাকা অবস্থায় নোটিফিকেশন আসার জন্য)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 মেসেজ পাওয়া গেছে: ${message.notification?.title}");
      if (message.notification != null) {
        display(message);
      }
    });
  }

  // ৫. নোটিফিকেশন দেখানোর ফাংশন
  static void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
      );

      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification?.title ?? "নতুন মেসেজ",
        message.notification?.body ?? "বিস্তারিত দেখতে ক্লিক করুন",
        notificationDetails,
        payload: message.data['route'], // যদি ডাটা পাস করতে চান
      );
    } catch (e) {
      print("❌ Error displaying notification: $e");
    }
  }
}
