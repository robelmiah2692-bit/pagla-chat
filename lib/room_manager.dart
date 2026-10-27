import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:pagla_chat/room_exit_handler.dart';
import 'package:pagla_chat/services/floating_bubble_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomManager {
  static final RoomManager _instance = RoomManager._internal();
  factory RoomManager() => _instance;
  RoomManager._internal();

  String? activeRoomId;
  int currentSeatIndex = -1;
  RtcEngine? engine;
  bool isMinimized = false;

  VoidCallback? onForceExit;

  // 🔥 সুনিশ্চিতভাবে এগোরা ইঞ্জিন ডিসপোজ ও রিলিজ করার স্ট্যাটিক মেথড
  static Future<void> disposeAgoraEngine(RtcEngine? rtcEngine) async {
    if (rtcEngine != null) {
      try {
        await rtcEngine.stopPreview();
        await rtcEngine.leaveChannel();
        await rtcEngine.release();
        debugPrint("🛑 [Agora] Engine successfully left channel and released completely!");
      } catch (e) {
        debugPrint("❌ [Agora] Error releasing engine: $e");
      }
    }
  }

  // 🔥 সুপার পাওয়ারফুল ফোর্স এক্সিট ও রুম ক্লিনআপ হ্যান্ডলার
  void forceExitOldRoom() async {
    if (activeRoomId != null) {
      String oldRoomId = activeRoomId!;
      debugPrint("🚨 Force exiting old room: $oldRoomId (Saved Seat Index: $currentSeatIndex)");

      // ১. সবার আগে এগোরার অডিও চ্যানেল বন্ধ ও ইঞ্জিন রিলিজ করা যাতে কোনোভাবেই কথা ক্রস না হয়
      if (engine != null) {
        await disposeAgoraEngine(engine);
        engine = null;
      }

      try {
        String currentAuthUid = FirebaseAuth.instance.currentUser?.uid ?? "";

        // ২. ইউজারের নিজস্ব সংক্ষিপ্ত uID খুঁজে বের করা
        String myuID = "";
        if (currentAuthUid.isNotEmpty) {
          try {
            var userDoc = await FirebaseFirestore.instance
                .collection('users')
                .where('authUID', isEqualTo: currentAuthUid)
                .limit(1)
                .get();
            if (userDoc.docs.isNotEmpty) {
              myuID = userDoc.docs.first.data()['uID']?.toString() ?? "";
            }
          } catch (e) {
            debugPrint("❌ Failed to fetch uID during force exit: $e");
          }
        }

        // ৩. যদি সিট ইনডেক্স জানা থাকে, সরাসরি RTDB ও Firestore থেকে সিট ক্লিয়ার করো
        if (currentSeatIndex != -1) {
          await _clearSeatCompletely(oldRoomId, currentSeatIndex);
        }

        // ৪. সিকিউরিটি স্ক্যান: RTDB-এর সমস্ত সিট চেক করে এই uID বা authUID যেখানেই পাবে, সব ক্লিয়ার করে দেবে
        try {
          final seatsRef = FirebaseDatabase.instance.ref('rooms/$oldRoomId/seats');
          final seatSnapshot = await seatsRef.get();

          if (seatSnapshot.exists && seatSnapshot.value != null) {
            Map<dynamic, dynamic> seatsMap = (seatSnapshot.value is Map)
                ? seatSnapshot.value as Map
                : (seatSnapshot.value as List).asMap();

            seatsMap.forEach((key, value) {
              if (value != null && value is Map) {
                String seatAuth = value['authUID']?.toString() ?? "";
                String seatUserId = value['userId']?.toString() ?? "";
                String seatUIDField = value['uID']?.toString() ?? "";

                if ((currentAuthUid.isNotEmpty && (seatAuth == currentAuthUid || seatUserId == currentAuthUid)) ||
                    (myuID.isNotEmpty && seatUIDField == myuID)) {
                  int foundIndex = int.tryParse(key.toString()) ?? -1;
                  if (foundIndex != -1) {
                    debugPrint("🧹 Found user sitting on old room seat $foundIndex. Cleaning up completely...");
                    _clearSeatCompletely(oldRoomId, foundIndex);
                  }
                }
              }
            });
          }
        } catch (e) {
          debugPrint("❌ Error scanning seats during force exit: $e");
        }

        // ৫. RoomExitHandler দিয়ে ভিউয়ার্স ও ইউজার লিস্ট ক্লিন করা
        if (currentAuthUid.isNotEmpty) {
          await RoomExitHandler.removeUserFromRoom(oldRoomId, currentAuthUid);
        }
        if (myuID.isNotEmpty) {
          await RoomExitHandler.removeUserFromRoom(oldRoomId, myuID);
        }

      } catch (e) {
        debugPrint("❌ Error during forceExitOldRoom cleanup: $e");
      }

      // ৬. কাস্টম এক্সিট হ্যান্ডলার রান করা
      if (onForceExit != null) {
        onForceExit!();
      }

      // ৭. বাবল হাইড করা
      FloatingBubbleService.hide();

      // ৮. ফুল রিসেট করা
      activeRoomId = null;
      currentSeatIndex = -1;
      onForceExit = null;
      isMinimized = false;
      engine = null;
    }
  }

  Future<void> _clearSeatCompletely(String roomId, int seatIndex) async {
    try {
      await FirebaseDatabase.instance
          .ref('rooms/$roomId/seats/$seatIndex')
          .update({
        'isOccupied': false,
        'userName': '',
        'userImage': '',
        'status': 'empty',
        'isMicOn': false,
        'authUID': '',
        'userId': '',
        'uID': '',
        'userFrame': '',
        'giftCount': 0,
        'vip_xp': 0,
      });

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('seats')
          .doc(seatIndex.toString())
          .update({
        'isOccupied': false,
        'userName': '',
        'userImage': '',
        'status': 'empty',
        'isMicOn': false
      });

      debugPrint("✅ Old room ($roomId) seat $seatIndex completely cleared!");
    } catch (e) {
      debugPrint("❌ Failed to clear seat $seatIndex in room $roomId: $e");
    }
  }

  void reset() async {
    if (engine != null) {
      await disposeAgoraEngine(engine);
    }
    activeRoomId = null;
    currentSeatIndex = -1;
    isMinimized = false;
    engine = null;
    onForceExit = null;
  }
}