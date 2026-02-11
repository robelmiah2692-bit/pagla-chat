import 'package:flutter/material.dart';

class AppConstants {
  // আপনার সেই স্পেশাল ক্লিয়ার ব্যাকগ্রাউন্ড ইমেজ পাথ
  static const String backgroundImage = "assets/images/clear_bg.jpg"; 

  // অ্যাপের থিম কালার (Achat স্টাইল ডার্ক নিওন)
  static const Color primaryColor = Color(0xFF0F0F1E);
  static const Color accentColor = Color(0xFFE91E63); // পিঙ্ক নিওন
  static const Color cardColor = Color(0xFF1A1A2E);
  static const Color diamondColor = Color(0xFF00E5FF); // ডায়মন্ডের জন্য সাইয়ান কালার

  // টেক্সট স্টাইল
  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
}
