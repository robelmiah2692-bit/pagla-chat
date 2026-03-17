import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class AgoraStatusChecker {
  // ১. মেথডটিকে নিরাপদ করার জন্য context চেক যোগ করা হয়েছে
  static void listenToEvents(RtcEngine? engine, BuildContext context) {
    // ইঞ্জিন নাল থাকলে ফাংশনটি কাজ করবে না, ফলে ক্রাশ হবে না
    if (engine == null) return;

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _showSnackBar(context, "✅ আপনি রুমে সফলভাবে যুক্ত হয়েছেন", Colors.green);
        },

        onConnectionStateChanged: (connection, state, reason) {
          if (state == ConnectionStateType.connectionStateReconnecting) {
            _showSnackBar(context, "📡 নেটওয়ার্ক দুর্বল, পুনরায় চেষ্টা করা হচ্ছে...", Colors.orange);
          } else if (state == ConnectionStateType.connectionStateFailed) {
            _showSnackBar(context, "❌ কানেকশন বিচ্ছিন্ন হয়েছে!", Colors.red);
          }
        },

        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _showSnackBar(context, "⚠️ আপনার কানেকশন টোকেন শেষ হয়ে যাচ্ছে!", Colors.orange);
        },

        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Error [$err]: $msg");
          if (msg.toLowerCase().contains("mic") || msg.toLowerCase().contains("audio")) {
             _showSnackBar(context, "⚠️ মাইক সমস্যা: $msg", Colors.red);
          }
        },
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    // সমাধান: context এখনো স্ক্রিনে আছে কি না তা নিশ্চিত করা
    if (!Navigator.canPop(context) && !context.mounted) return;

    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          backgroundColor: color.withOpacity(0.9),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint("SnackBar Error: $e");
    }
  }
}
