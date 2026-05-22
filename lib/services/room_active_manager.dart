import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🇧🇩 [বাংলা মার্ক]: রুমে একটিভ থাকার কারণে এক্সপি বাড়ানোর আলাদা ফিচার ম্যানেজার ফাইল
class RoomActiveManager {
  Timer? _activeXpTimer;

  /// 🚀 রুমে ঢোকার পর টাইমার স্টার্ট করার ফাংশন ভাই
  void startTimer({required String userId, int minutesInterval = 1, int xpAmount = 1}) {
    // আগের কোনো টাইমার চালু থাকলে তা আগে বন্ধ করে নেওয়া ভালো ভাই
    stopTimer();

    if (userId.isEmpty) return;

    _activeXpTimer = Timer.periodic(Duration(minutes: minutesInterval), (timer) async {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          // 📈 ডাটাবেজে রিয়েল-টাইমে 'totalActiveXp' ফিল্ডে এক্সপি বাড়বে ভাই
          'totalActiveXp': FieldValue.increment(xpAmount),
        });
        debugPrint("🕒 [PaglaChat] রুমে $minutesInterval মিনিট একটিভ থাকার জন্য $xpAmount XP বেড়েছে!");
      } catch (e) {
        debugPrint("❌ [RoomActiveManager Error]: $e");
      }
    });
  }

  /// 🛑 ইউজার রুম থেকে বের হয়ে গেলে টাইমার বন্ধ করার ফাংশন ভাই
  void stopTimer() {
    if (_activeXpTimer != null) {
      _activeXpTimer!.cancel();
      _activeXpTimer = null;
      debugPrint("🛑 [PaglaChat] একটিভ এক্সপি টাইমার সফলভাবে বন্ধ হয়েছে।");
    }
  }
}