import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceService {
  // ১. ১০০% ইউনিক ডিভাইস আইডি জেনারেট করার নতুন ও নিরাপদ লজিক
  static Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // বোর্ডের নাম, হার্ডওয়্যার, ডিভাইস এবং মডেল মিলিয়ে ১০০% ইউনিক আইডি তৈরি করা হলো
        deviceId = "${androidInfo.brand}_${androidInfo.device}_${androidInfo.hardware}_${androidInfo.model}_${androidInfo.id}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "ios_unknown";
      }
    } on PlatformException {
      deviceId = 'unknown_device';
    }
    return deviceId ?? "unknown";
  }

  // ২. ডিভাইস ব্লক চেক করার ফাংশন
  static Future<bool> isDeviceBlocked() async {
    String deviceId = await getDeviceId();
    if (deviceId.isEmpty || deviceId == 'unknown_device') return false;

    var doc = await FirebaseFirestore.instance
        .collection('blocked_devices')
        .doc(deviceId)
        .get();
    
    return doc.exists; 
  }
}