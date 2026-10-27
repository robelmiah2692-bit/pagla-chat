import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RoomExitHandler {
  // ১. রুম এন্ড এবং সব ডাটা ক্লিনিং (RTDB ভিউয়ার্স ও সিট সহ)
  static Future<void> endRoom(String roomId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference roomRef = firestore.collection('rooms').doc(roomId);

      // ফায়ারস্টোরে রুমের মূল ডাটা রিসেট করা
      await roomRef.update({
        'isActive': false,
        'seats': [],
        'userCount': 0,
        'usersInRoom': [],
        'viewerList': [], 
      });

      // ✅ রিয়েলটাইম ডাটাবেস (RTDB) থেকে ভিউয়ার্স এবং সিট সম্পূর্ণ মুছে ফেলা
      await FirebaseDatabase.instance.ref('rooms/$roomId/viewers').remove();
      await FirebaseDatabase.instance.ref('rooms/$roomId/seats').remove();

      // ব্যাকগ্রাউন্ডে ট্রানজেকশনের মাধ্যমে অন্যান্য ক্লিনিং
      firestore.runTransaction((transaction) async {
        var roomUsers = await roomRef.collection('users').get();
        for (var doc in roomUsers.docs) {
          transaction.delete(doc.reference);
        }

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

  // ২. ইউজার রুম থেকে বের হওয়ার সময় RTDB ভিউয়ার্স থেকে রিমুভ করার ফাংশন
  static Future<void> removeUserFromRoom(String roomId, String userId) async {
    try {
      if (userId.isEmpty) return;

      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'usersInRoom': FieldValue.arrayRemove([userId.toString()])
      });

      await FirebaseDatabase.instance
          .ref('rooms/$roomId/viewers/$userId')
          .remove();
    } catch (e) {
      debugPrint("DEBUG ERROR: Remove user failed: $e");
    }
  }

  // ৩. সেফ হ্যান্ডল এক্সিট লজিক (যা আর সাধারণ ইউজারের জন্য ভুলবশত রুম বন্ধ করবে না)
  static Future<bool> handleExit(String roomId, String currentUserId,
      List<String> adminList, String ownerId) async {
    try {
      // ইউজারকে ভিউয়ার্স থেকে রিমুভ করা
      await removeUserFromRoom(roomId, currentUserId);

      String ownerIdStr = ownerId.toString().trim();
      List<String> adminIdsStr = adminList.map((e) => e.toString().trim()).toList();
      String currentUserIdStr = currentUserId.toString().trim();

      // 🔥 সেফটি গার্ড: যদি বের হওয়া ইউজার নিজে মালিক বা কোনো অ্যাডমিন না হয়, 
      // তবে রুম বন্ধ করার কোনো প্রশ্নই আসে না! সরাসরি রিটার্ন করবে।
      bool isExitingUserOwnerOrAdmin = (currentUserIdStr == ownerIdStr || adminIdsStr.contains(currentUserIdStr));
      
      if (!isExitingUserOwnerOrAdmin) {
        debugPrint("DEBUG: সাধারণ ইউজার বের হয়েছে, রুম আগের মতোই সচল থাকবে।");
        return true;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      bool isPresent = false;

      // ২. সিট চেক করা (RTDB)
      DatabaseReference seatsRef = FirebaseDatabase.instance.ref('rooms/$roomId/seats');
      DataSnapshot seatsSnapshot = await seatsRef.get();

      if (seatsSnapshot.exists && seatsSnapshot.value != null) {
        Map<dynamic, dynamic> seatsData = (seatsSnapshot.value is Map)
            ? seatsSnapshot.value as Map
            : (seatsSnapshot.value as List).asMap();

        for (var key in seatsData.keys) {
          var seat = seatsData[key];
          if (seat != null && seat is Map) {
            String seatUID = seat['uID']?.toString().trim() ?? "";
            String seatAuth = seat['authUID']?.toString().trim() ?? "";
            String seatUserId = seat['userId']?.toString().trim() ?? "";

            // স্ট্রং ম্যাচিং: অনার বা যেকোনো অ্যাডমিন সিটে আছে কি না
            if ((ownerIdStr.isNotEmpty && (seatUID == ownerIdStr || seatAuth == ownerIdStr || seatUserId == ownerIdStr)) ||
                adminIdsStr.any((adminId) => adminId.isNotEmpty && (seatUID == adminId || seatAuth == adminId || seatUserId == adminId))) {
              isPresent = true;
              break;
            }
          }
        }
      }

      // ৩. ভিউয়ার লিস্ট চেক করা (যদি সিটে না থাকে) - RTDB
      if (!isPresent) {
        DatabaseReference viewersRef = FirebaseDatabase.instance.ref('rooms/$roomId/viewers');
        DataSnapshot viewersSnapshot = await viewersRef.get();

        if (viewersSnapshot.exists && viewersSnapshot.value != null) {
          Map<dynamic, dynamic> viewersData = (viewersSnapshot.value is Map)
              ? viewersSnapshot.value as Map
              : (viewersSnapshot.value as List).asMap();

          for (var key in viewersData.keys) {
            var viewer = viewersData[key];
            if (viewer != null && viewer is Map) {
              String viewerUID = viewer['uID']?.toString().trim() ?? "";
              String viewerAuth = viewer['authUID']?.toString().trim() ?? "";

              if ((ownerIdStr.isNotEmpty && (viewerUID == ownerIdStr || viewerAuth == ownerIdStr)) ||
                  adminIdsStr.any((adminId) => adminId.isNotEmpty && (viewerUID == adminId || viewerAuth == adminId))) {
                isPresent = true;
                break;
              }
            }
          }
        }
      }

      // ৪. শুধুমাত্র তখনই রুম বন্ধ হবে যখন রুমে মালিক বা অ্যাডমিনদের কেউই থাকবে না!
      if (!isPresent) {
        debugPrint("DEBUG: রুমে মালিক বা কোনো অ্যাডমিন উপস্থিত নেই, রুম বন্ধ করা হচ্ছে।");
        await endRoom(roomId);
      } else {
        debugPrint("DEBUG: রুমে মালিক বা অ্যাডমিন এখনো আছে, রুম বন্ধ হবে না।");
      }

      return true;
    } catch (e) {
      debugPrint("DEBUG ERROR: handleExit failed: $e");
      return true;
    }
  }
}