import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class WebPermissionHandler {
  static Future<bool> requestAudioPermission() async {
    if (kIsWeb) {
      // ওয়েবে ব্রাউজার অটোমেটিক হ্যান্ডেল করবে, শুধু চেক পাঠাচ্ছি
      print("Web: ব্রাউজার মাইক পারমিশন চাইবে...");
      return true; 
    } else {
      // মোবাইলের জন্য ম্যানুয়াল পারমিশন
      var status = await Permission.microphone.request();
      return status.isGranted;
    }
  }
}
