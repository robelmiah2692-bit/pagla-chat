import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart'; // kIsWeb চেক করার জন্য লাগবে
// কন্ডিশনাল ইম্পোর্ট ব্যবহার করা ভালো, তবে আপাতত সহজ করার জন্য নিচে লজিক দিচ্ছি
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class LiveNotificationService {
  static const String notificationChannelId = 'live_room_channel';
  static const int notificationId = 888;

  // সার্ভিস শুরু করার ফাংশন
  static Future<void> initializeService() async {
    // [FIX] ওয়েবে এই সার্ভিস রান করা যাবে না, তাই রিটার্ন করে দিচ্ছি
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

    // নোটিফিকেশন আপডেট রাখার জন্য টাইমার
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "পাগলা চ্যাট রুম লাইভ 🎙️",
            content: "আপনি কথা বলছেন...",
          );
        }
      }
    });
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }
}
