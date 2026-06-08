import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🇧🇩 [বাংলা মার্ক]: রুমে একটিভ থাকার কারণে এক্সপি বাড়ানোর আলাদা ফিচার ম্যানেজার ফাইল
class RoomActiveManager {
  Timer? _activeXpTimer;

  /// 🚀 রুমে ঢোকার পর টাইমার স্টার্ট করার ফাংশন ভাই
  /// [uID] = ৬ ডিজিটের ইউজার আইডি (যা ডকুমেন্ট আইডি হিসেবে কাজ করবে)
  /// [authUID] = ফায়ারবেস অথেন্টিকেশনের লম্বা UID
  /// [email] = ইউজারের ইমেইল এড্রেস
  void startTimer(
      {required String uID,
      required String authUID,
      required String email,
      int minutesInterval = 20,
      int xpAmount = 1}) {
    // সেফটির জন্য আগের কোনো টাইমার চালু থাকলে তা বন্ধ করে নেওয়া ভাই
    stopTimer();

    if (uID.isEmpty) {
      return;
    }

    _activeXpTimer =
        Timer.periodic(Duration(minutes: minutesInterval), (timer) async {
      try {
        // 🎯 SetOptions(merge: true) ব্যবহারের কারণে পুরাতন কোনো ফিল্ড ডিলিট বা মিস হবে না ভাই।
        // যদি ডাটাবেজে ফিল্ড আগে থেকে নাও থাকে, তবে সে নতুন করে এগুলো তৈরি করে নেবে।
        await FirebaseFirestore.instance.collection('users').doc(uID).set({
          'totalActiveXp':
              FieldValue.increment(xpAmount), // এক্সপি ১ করে বাড়বে ভাই
          'uID': uID, // ৬ ডিজিটের আইডি সুরক্ষিত থাকবে
          'authUID': authUID, // ফায়ারবেস অথ আইডি সুরক্ষিত থাকবে
          'email': email, // ইউজারের ইমেইল সুরক্ষিত থাকবে
        }, SetOptions(merge: true));
      } catch (e) {}
    });
  }

  /// 🛑 ইউজার রুম থেকে বের হয়ে গেলে টাইমার বন্ধ করার ফাংশন ভাই
  void stopTimer() {
    if (_activeXpTimer != null) {
      _activeXpTimer!.cancel();
      _activeXpTimer = null;
    }
  }
}
