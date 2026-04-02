import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // kDebugMode এর জন্য

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১️⃣ রুমের সব ডাটা সেভ রাখা (প্যারামিটার ফিক্স করা হয়েছে)
  Future<void> updateRoomFullData({
    required String roomId,
    required String roomName,
    required String roomImage,
    required bool isLocked,
    required String wallpaper,
    required int followers,
    required int totalDiamonds,
    String? uID,        // 👈 নতুন যোগ করা হলো (বিল্ড এরর ফিক্সের জন্য)
    String? ownerName,  // 👈 নতুন যোগ করা হলো (বিল্ড এরর ফিক্সের জন্য)
  }) async {
    final User? user = _auth.currentUser;
    if (user == null || roomId.isEmpty) return;

    try {
      await _firestore.collection('rooms').doc(roomId).set({
        'roomId': roomId,
        'roomName': roomName,
        'roomImage': roomImage,
        'isLocked': isLocked,
        'wallpaper': wallpaper,
        'followerCount': followers,
        'totalDiamonds': totalDiamonds,
        'adminId': user.uid,
        'isLive': true,
        'uID': uID ?? user.uid,             // 👈 ডাটাবেসে ওনার আইডি সেভ হবে
        'ownerName': ownerName ?? 'Owner',   // 👈 ডাটাবেসে ওনার নাম সেভ হবে
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("✅ Room Synced with Owner Info");
    } catch (e) {
      debugPrint("❌ Room Update Error: $e");
    }
  }

  // ২️⃣ সিটে বসার পর ডাটা আপডেট করা (এরর ফ্রি লজিক)
  Future<void> updateSeatData({
    required String roomId,
    required int seatIndex,
    required String uName,
    required String uImage,
    required bool isOccupied,
  }) async {
    final User? user = _auth.currentUser;
    if (roomId.isEmpty || user == null) return;

    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'seats.$seatIndex': {
          'userName': uName,
          'userImage': uImage,
          'isOccupied': isOccupied,
          'uid': user.uid,
          'at': DateTime.now().toIso8601String(),
        }
      });
    } catch (e) {
      debugPrint("❌ Seat Update Error: $e");
    }
  }

  // ৩️⃣ ইউজার ডায়মন্ড ব্যালেন্স স্ট্রিম
  Stream<DocumentSnapshot>? getUserDiamonds() {
    final String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return null;
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // ৪️⃣ গিফট লজিক
  Future<bool> sendGift({
    required String roomId,
    required int giftValue,
    required String receiverId,
  }) async {
    final User? sender = _auth.currentUser;
    if (sender == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(sender.uid).get();
      final userData = userDoc.data();
      if (!userDoc.exists || userData == null) return false;
      
      final int currentBalance = userData['diamonds'] ?? 0;

      if (currentBalance >= giftValue) {
        // ১. সেন্ডার এর ডায়মন্ড কমানো
        await _firestore.collection('users').doc(sender.uid).update({
          'diamonds': FieldValue.increment(-giftValue),
        });

        // ২. রুমের টোটাল ডায়মন্ড বাড়ানো
        await _firestore.collection('rooms').doc(roomId).update({
          'totalDiamonds': FieldValue.increment(giftValue),
        });

        // ৩. রিসিভার এর ডায়মন্ড বাড়ানো
        if (receiverId.isNotEmpty) {
          await _firestore.collection('users').doc(receiverId).update({
            'receivedDiamonds': FieldValue.increment(giftValue),
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Gift Error: $e");
      return false;
    }
  }

  // ৫️⃣ রুম থেকে বের হলে ডাটা আপডেট
  Future<void> leaveRoom(String roomId) async {
    final String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'currentRoomId': "",
      });
    } catch (e) {
      debugPrint("❌ Leave Error: $e");
    }
  }
}
