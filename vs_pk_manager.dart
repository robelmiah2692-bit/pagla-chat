import 'dart:async';
import 'package:flutter/material.dart';

class VSPKManager {
  Timer? _pkTimer;
  int _remainingSeconds = 0;
  final Function(int) onTick; // প্রতি সেকেন্ডে আপডেট করার জন্য
  final VoidCallback onFinished; // সময় শেষ হলে কল হবে

  VSPKManager({required this.onTick, required this.onFinished});

  // পিকে শুরু করার ফাংশন (মিনিট অনুযায়ী)
  void startPK(int minutes) {
    stopPK(); // আগে চললে বন্ধ করে নতুন করে শুরু হবে
    _remainingSeconds = minutes * 60;

    _pkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        onTick(_remainingSeconds); // মেইন ফাইলে সময় পাঠাবে
      } else {
        stopPK();
        onFinished(); // পিকে শেষ করার ফাংশন কল হবে
      }
    });
  }

  // পিকে মাঝপথে বন্ধ করার জন্য
  void stopPK() {
    _pkTimer?.cancel();
    _pkTimer = null;
  }

  // সময়কে সুন্দরভাবে (MM:SS) ফরম্যাটে দেখানোর জন্য
  String formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
