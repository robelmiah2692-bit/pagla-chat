import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // অ্যান্ড্রয়েডের জন্য হাই ইম্পর্টেন্স চ্যানেল
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // ID
    'High Importance Notifications', // Title
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initNotification() async {
    // ১. পারমিশন রিকোয়েস্ট
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ২. টোকেন নেওয়া এবং ডাটাবেসে সেভ করা
    String? token = await _fcm.getToken();
    if (token != null) {
      _saveTokenToFirestore(token);
    }

    // ৩. টোকেন রিফ্রেশ হলে আপডেট করা
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // ৪. লোকাল নোটিফিকেশন চ্যানেল সেটআপ
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidSettings);
        
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // নোটিফিকেশনে ক্লিক করলে এখানে লজিক লিখবেন (যেমন: নির্দিষ্ট পেজে যাওয়া)
        print("🔔 ক্লিক করা হয়েছে: ${details.payload}");
      },
    );

    // ৫. ফরগ্রাউন্ড লিসেনার (অ্যাপ খোলা থাকা অবস্থায়)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        display(message);
      }
    });

    // ৬. ব্যাকগ্রাউন্ডে থাকা অবস্থায় ক্লিক করলে হ্যান্ডেল করা
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       print("🚀 ব্যাকগ্রাউন্ড থেকে অ্যাপ ওপেন হয়েছে: ${message.data}");
    });
  }

  // --- ডাটাবেসে টোকেন সেভ করার ফাংশন ---
  void _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      }).catchError((e) => print("Token Update Error: $e"));
    }
  }

  // --- লাইভ রুম বা ফলোয়ার নোটিফিকেশনের জন্য টপিক সাবস্ক্রাইব ---
  Future<void> subscribeToTopic(String topicName) async {
    await _fcm.subscribeToTopic(topicName);
    print("✅ Subscribed to topic: $topicName");
  }

  // ৫. নোটিফিকেশন দেখানোর ফাংশন (Display)
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
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
      );

      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification?.title ?? "নতুন নোটিফিকেশন",
        message.notification?.body ?? "",
        notificationDetails,
        payload: message.data['route'], 
      );
    } catch (e) {
      print("❌ Error: $e");
    }
  }
}
