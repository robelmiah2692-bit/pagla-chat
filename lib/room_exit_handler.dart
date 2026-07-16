import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RoomExitHandler {
  // ১. রুম এন্ড এবং সব ডাটা ক্লিনিং
  static Future<void> endRoom(String roomId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference roomRef = firestore.collection('rooms').doc(roomId);

      // সব ডাটা রিসেট করা
      await roomRef.update({
        'isActive': false,
        'seats': [],
        'userCount': 0,
        'usersInRoom': [],
        'viewerList': [], // ভিউয়ার লিস্টও ক্লিয়ার হবে
      });

      // ব্যাকগ্রাউন্ডে ট্রানজেকশনের মাধ্যমে ক্লিনিং
      firestore.runTransaction((transaction) async {
        // ইউজার কালেকশন
        var roomUsers = await roomRef.collection('users').get();
        for (var doc in roomUsers.docs) {
          transaction.delete(doc.reference);
        }

        // মেসেজ কালেকশন
        var chatMessages = await roomRef.collection('messages').get();
        for (var msgDoc in chatMessages.docs) {
          transaction.delete(msgDoc.reference);
        }
      });
      debugPrint("DEBUG: Room $roomId ended completely.");
    } catch (e) {
      debugPrint("DEBUG ERROR: endRoom failed: $e");
    }
  }

  // ২. ইউজার রিমুভ করার ফাংশন
  static Future<void> removeUserFromRoom(String roomId, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'usersInRoom': FieldValue.arrayRemove([userId.toString()])
      });
    } catch (e) {
      debugPrint("DEBUG ERROR: Remove user failed: $e");
    }
  }

  static Future<bool> handleExit(String roomId, String currentUserId,
      List<String> adminList, String ownerId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // ১. ইউজার রিমুভ করুন
      await removeUserFromRoom(roomId, currentUserId);
      await Future.delayed(const Duration(seconds: 2));

      String ownerIdStr = ownerId.toString().trim();
      List<String> adminIdsStr = adminList.map((e) => e.toString().trim()).toList();
      bool isPresent = false;

      // ২. সিট চেক করা (RTDB)
      DatabaseReference seatsRef = FirebaseDatabase.instance.ref('rooms/$roomId/seats');
      DataSnapshot seatsSnapshot = await seatsRef.get();

      if (seatsSnapshot.exists) {
        Map<dynamic, dynamic> seatsData = seatsSnapshot.value as Map<dynamic, dynamic>;
        for (var key in seatsData.keys) {
          var seat = seatsData[key];
          String seatUID = seat['uID']?.toString().trim() ?? "";
          if (seatUID.isNotEmpty && (seatUID == ownerIdStr || adminIdsStr.contains(seatUID))) {
            isPresent = true;
            break;
          }
        }
      }

      // ৩. ভিউয়ার লিস্ট চেক করা (যদি সিটে না থাকে) - নতুন লজিক
      if (!isPresent) {
        DatabaseReference viewersRef = FirebaseDatabase.instance.ref('rooms/$roomId/viewers');
        DataSnapshot viewersSnapshot = await viewersRef.get();

        if (viewersSnapshot.exists) {
          Map<dynamic, dynamic> viewersData = viewersSnapshot.value as Map<dynamic, dynamic>;
          for (var key in viewersData.keys) {
            var viewer = viewersData[key];
            String viewerUID = viewer['uID']?.toString().trim() ?? "";
            if (viewerUID.isNotEmpty && (viewerUID == ownerIdStr || adminIdsStr.contains(viewerUID))) {
              isPresent = true;
              break;
            }
          }
        }
      }

      // ৪. রুম বন্ধ করার লজিক
      if (!isPresent) {
        debugPrint("DEBUG: কোথাও মালিক বা এডমিন নেই, রুম বন্ধ করা হচ্ছে।");
        await endRoom(roomId);
      } else {
        debugPrint("DEBUG: রুমে মালিক বা এডমিন উপস্থিত আছে, রুম বন্ধ হবে না।");
      }

      return true;
    } catch (e) {
      debugPrint("DEBUG ERROR: handleExit failed: $e");
      return true;
    }
  }
}