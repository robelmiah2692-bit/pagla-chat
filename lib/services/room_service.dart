import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১️⃣ রুমের সব ডাটা সেভ রাখা (Firebase Schema অনুযায়ী আপডেট করা হয়েছে)
  Future<void> updateRoomFullData({
    required String roomId,
    required String roomName,
    required String roomImage,
    required bool isLocked,
    required String wallpaper,
    required int followers,
    required int totalDiamonds,
    String? uID,        // মালিকের uID (যেমন: "153530")
    String? ownerName,  // মালিকের নাম
  }) async {
    final User? user = _auth.currentUser;
    if (user == null || roomId.isEmpty) return;

    try {
      // স্ক্রিনশট অনুযায়ী মালিকের ফিল্ডগুলো সেট করা হচ্ছে
      await _firestore.collection('rooms').doc(roomId).set({
        'roomId': roomId,
        'roomName': roomName,
        'roomImage': roomImage,
        'isLocked': isLocked,
        'wallpaper': wallpaper,
        'followerCount': followers,
        'totalDiamonds': totalDiamonds,
        'ownerId': uID ?? "",        // মালিকের uID এখানে সেভ হবে
        'uID': uID ?? "",            // Firebase screenshot অনুযায়ী
        'ownerName': ownerName ?? 'Owner',
        'isLive': true,
        'userCount': 1,              // ডিফল্ট ভ্যালু হিসেবে
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint("✅ Room Synced with Owner Info (uID: $uID)");
    } catch (e) {
      debugPrint("❌ Room Update Error: $e");
    }
  }

  // ২️⃣ সিটে বসার পর ডাটা আপডেট করা
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
          'uID': user.uid, // Firebase Auth ID
          'at': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      debugPrint("❌ Seat Update Error: $e");
    }
  }

  // ৩️⃣ ইউজার ডায়মন্ড ব্যালেন্স স্ট্রিম (ইউজার কালেকশন থেকে)
  Stream<DocumentSnapshot>? getUserDiamonds(String useruID) {
    if (useruID.isEmpty) return null;
    // আপনার স্ক্রিনশট অনুযায়ী 'users' কালেকশনে uID ডকুমেন্ট আইডি হিসেবে ব্যবহার হচ্ছে
    return _firestore.collection('users').doc(useruID).snapshots();
  }

  // ৪️⃣ গিফট লজিক
  Future<bool> sendGift({
    required String roomId,
    required int giftValue,
    required String senderuID,   // ইউজারের নিজস্ব uID (যেমন: "153530")
    required String receiveruID, // রিসিভারের uID
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(senderuID).get();
      if (!userDoc.exists) return false;
      
      final int currentBalance = userDoc.data()?['diamonds'] ?? 0;

      if (currentBalance >= giftValue) {
        WriteBatch batch = _firestore.batch();

        // ১. সেন্ডারের ডায়মন্ড কমানো
        DocumentReference senderRef = _firestore.collection('users').doc(senderuID);
        batch.update(senderRef, {'diamonds': FieldValue.increment(-giftValue)});

        // ২. রুমের টোটাল ডায়মন্ড বাড়ানো
        DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
        batch.update(roomRef, {'totalDiamonds': FieldValue.increment(giftValue)});

        // ৩. রিসিভারের ডায়মন্ড বাড়ানো (যদি থাকে)
        if (receiveruID.isNotEmpty) {
          DocumentReference receiverRef = _firestore.collection('users').doc(receiveruID);
          batch.update(receiverRef, {'receivedDiamonds': FieldValue.increment(giftValue)});
        }

        await batch.commit();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Gift Error: $e");
      return false;
    }
  }

  // ৫️⃣ রুম থেকে বের হলে ডাটা আপডেট
  Future<void> leaveRoom(String useruID) async {
    if (useruID.isEmpty) return;
    try {
      await _firestore.collection('users').doc(useruID).update({
        'currentRoomId': "",
      });
    } catch (e) {
      debugPrint("❌ Leave Error: $e");
    }
  }
}
