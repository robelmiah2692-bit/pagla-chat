import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class AgoraStatusChecker {
  // আগের মেসেজটি ট্র্যাকিং করার জন্য যাতে একই জিনিস বারবার না দেখায়
  static String? _lastMessage;

  static void listenToEvents(RtcEngine? engine, BuildContext context) {
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
          // মাইক বা অডিওর এররগুলো বারবার আসতে পারে, তাই সতর্ক থাকতে হবে
          if (msg.toLowerCase().contains("mic") || msg.toLowerCase().contains("audio")) {
             _showSnackBar(context, "⚠️ মাইক সমস্যা দেখা দিচ্ছে", Colors.red);
          }
        },
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    // ১. মাউন্টেড চেক এবং ডুপ্লিকেট মেসেজ চেক
    if (!context.mounted || _lastMessage == message) return;

    try {
      _lastMessage = message;
      final messenger = ScaffoldMessenger.of(context);
      
      // ২. hideCurrentSnackBar() এর কারণে অনেক সময় ঝিলিক মারে, তাই সরাসরি নতুন স্ন্যাপবার দেখানো ভালো
      messenger.clearSnackBars(); 

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          backgroundColor: color.withOpacity(0.8),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          // ৩. মার্জিন বাড়িয়ে দেওয়া হয়েছে যাতে এটি ভিউয়ার লিস্টের ওপর চাপ না দেয়
          margin: const EdgeInsets.only(bottom: 100, left: 50, right: 50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );

      // মেসেজটি শেষ হওয়ার পর ট্র্যাকিং ক্লিয়ার করা
      Future.delayed(const Duration(seconds: 3), () {
        _lastMessage = null;
      });
    } catch (e) {
      debugPrint("SnackBar Error: $e");
    }
  }
}