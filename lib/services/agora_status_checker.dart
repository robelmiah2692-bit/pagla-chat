import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class AgoraStatusChecker {
  // কানেকশন স্ট্যাটাস চেক করার জন্য একটি ফাংশন
  static void checkStatus(RtcEngine engine, BuildContext context) {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _showSnackBar(context, "✅ এগোরা কানেক্টেড! চ্যানেল: ${connection.channelId}", Colors.green);
        },
        onError: (ErrorCodeType err, String msg) {
          _showSnackBar(context, "❌ এগোরা এরর: $err - $msg", Colors.red);
          print("Agora Error: $msg");
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _showSnackBar(context, "👤 নতুন ইউজার জয়েন করেছে (UID: $remoteUid)", Colors.blue);
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _showSnackBar(context, "⚠️ আপনার টোকেন শেষ হয়ে যাচ্ছে!", Colors.orange);
        },
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
