import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class AgoraStatusChecker {
  // আগের মতো static না রেখে একটি ডিসপোজেবল লজিক ব্যবহার করা ভালো
  static void listenToEvents(RtcEngine engine, BuildContext context) {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        // ১. সফলভাবে জয়েন করলে
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _showSnackBar(context, "✅ আপনি রুমে সফলভাবে যুক্ত হয়েছেন", Colors.green);
        },

        // ২. নেট চলে গেলে বা রিকানেক্ট করার সময় (আপনার জন্য খুব জরুরি)
        onConnectionStateChanged: (connection, state, reason) {
          if (state == ConnectionStateType.connectionStateReconnecting) {
            _showSnackBar(context, "📡 নেটওয়ার্ক দুর্বল, পুনরায় চেষ্টা করা হচ্ছে...", Colors.orange);
          } else if (state == ConnectionStateType.connectionStateFailed) {
            _showSnackBar(context, "❌ কানেকশন বিচ্ছিন্ন হয়েছে!", Colors.red);
          }
        },

        // ৩. টোকেন শেষ হতে থাকলে
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _showSnackBar(context, "⚠️ টোকেন এক্সপায়ার হতে যাচ্ছে!", Colors.orange);
        },

        // ৪. কোন বড় এরর হলে
        onError: (ErrorCodeType err, String msg) {
          // নির্দিষ্ট কিছু এরর যেটা ইউজারকে জানানো দরকার
          if (err == ErrorCodeType.errStartCamera || err == ErrorCodeType.errJoinChannelRejected) {
             _showSnackBar(context, "⚠️ এগোরা সমস্যা: $err", Colors.red);
          }
          debugPrint("Agora Error [$err]: $msg");
        },
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    // আগের মেসেজ থাকলে তা সরিয়ে নতুনটা দেখাবে
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        backgroundColor: color.withOpacity(0.8), // কিছুটা স্বচ্ছ যাতে বিরক্ত না লাগে
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating, // ভেসে থাকবে দেখতে সুন্দর লাগবে
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
