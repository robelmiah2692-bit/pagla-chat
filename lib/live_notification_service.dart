import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LiveNotificationService {
  static const String notificationChannelId = 'live_room_channel';
  static const int notificationId = 888;

  // সার্ভিস শুরু করার ফাংশন
  static Future<void> initializeService() async {
    if (kIsWeb) {
      print("Web: Background service is not supported.");
      return; 
    }

    final service = FlutterBackgroundService();

    // নোটিফিকেশন চ্যানেল সেটআপ (অ্যান্ড্রয়েডের জন্য)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Live Voice Room',
      description: 'রুম ব্যাকগ্রাউন্ডে চললে এই নোটিফিকেশন দেখাবে',
      importance: Importance.low, 
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, 
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'ভয়েস রুম লাইভ',
        initialNotificationContent: 'আপনি বর্তমানে রুমে যুক্ত আছেন',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // 🛠️ [FIX] অপ্রয়োজনীয় প্রতি সেকেন্ডের টাইমারটি রিমুভ করা হয়েছে, 
    // যা ব্যাকগ্রাউন্ডে প্রসেসর ও ব্যাটারি সেভ করবে।
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }
}