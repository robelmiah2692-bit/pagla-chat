import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class AgoraStatusChecker {
  static void listenToEvents(RtcEngine engine, BuildContext context) {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        // ১. সফলভাবে জয়েন করলে
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _showSnackBar(context, "✅ আপনি রুমে সফলভাবে যুক্ত হয়েছেন", Colors.green);
        },

        // ২. নেট চলে গেলে অটো-রিকানেক্ট লজিককে সাপোর্ট করা
        onConnectionStateChanged: (connection, state, reason) {
          if (state == ConnectionStateType.connectionStateReconnecting) {
            _showSnackBar(context, "📡 নেটওয়ার্ক দুর্বল, পুনরায় চেষ্টা করা হচ্ছে...", Colors.orange);
          } else if (state == ConnectionStateType.connectionStateFailed) {
            _showSnackBar(context, "❌ কানেকশন বিচ্ছিন্ন হয়েছে!", Colors.red);
          }
        },

        // ৩. টোকেন শেষ হতে থাকলে
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _showSnackBar(context, "⚠️ আপনার কানেকশন টোকেন শেষ হয়ে যাচ্ছে!", Colors.orange);
        },

        // ৪. এরর হ্যান্ডলিং (যেখানে বিল্ড এরর হচ্ছিল)
        onError: (ErrorCodeType err, String msg) {
          // নির্দিষ্ট নাম 'errStartCamera' ব্যবহার না করে সরাসরি এরর চেক করা
          debugPrint("Agora Error [$err]: $msg");
          
          if (msg.toLowerCase().contains("mic") || msg.toLowerCase().contains("audio")) {
             _showSnackBar(context, "⚠️ মাইক সমস্যা: $msg", Colors.red);
          }
        },
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    // মেসেজগুলো যাতে একে অপরের ওপর না জমে যায়
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: color.withOpacity(0.9),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
