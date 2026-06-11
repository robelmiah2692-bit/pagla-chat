import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
void _firebaseMessagingBackgroundHandler(NotificationResponse details) {
  print("🔔 ব্যাকগ্রাউন্ড থেকে ক্লিক হয়েছে");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    String? token = await _fcm.getToken();
    if (token != null) _saveTokenToFirestore(token);

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        print("🔔 ক্লিক করা হয়েছে");
      },
      onDidReceiveBackgroundNotificationResponse: _firebaseMessagingBackgroundHandler,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  void _saveTokenToFirestore(String token) async {
    // এখানে আপনার সেই ৬ ডিজিটের আইডিটি লাগবে যা আপনার ডাটাবেসের ডকুমেন্টের নাম।
    // আমি আউথ থেকে সরাসরি UID নিচ্ছি না, বরং আপনার ডাটাবেসের ওই ৬ ডিজিটের আইডিটি পাওয়ার চেষ্টা করছি।
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // এখানে আপনার অ্যাপে যে ৬ ডিজিটের আইডিটি লজিক্যালি আছে সেটি দিন। 
      // আমি ধরে নিচ্ছি আপনার অ্যাপের কোনো স্টেট ম্যানেজমেন্টে বা কোথাও এই আইডিটি আছে।
      // যদি আপনার কাছে আইডিটি সরাসরি না থাকে, তবে Firestore থেকে সার্চ করে নিতে হবে।
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email) // যদি ইমেইল দিয়ে ৬ ডিজিটের আইডি মেলানো যায়
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id; // এটাই সেই ৬ ডিজিটের আইডি
        
        await FirebaseFirestore.instance.collection('users').doc(docId).set(
            {'fcmToken': token}, SetOptions(merge: true));
            
        print("✅ সফলভাবে আপডেট হয়েছে: $docId");
      } else {
        print("⚠️ ডকুমেন্ট পাওয়া যায়নি, নতুন কিছু তৈরি করা হবে না।");
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}