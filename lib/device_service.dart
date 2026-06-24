import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceService {
  static Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // অ্যান্ড্রয়েড ইউনিক আইডি
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
    return null;
  }

  static Future<bool> isDeviceBlocked() async {
    String? deviceId = await getDeviceId();
    if (deviceId == null) return false;

    // 'blocked_devices' কালেকশনে আইডি চেক করা হচ্ছে
    var doc = await FirebaseFirestore.instance
        .collection('blocked_devices')
        .doc(deviceId)
        .get();
    
    return doc.exists; 
  }
}