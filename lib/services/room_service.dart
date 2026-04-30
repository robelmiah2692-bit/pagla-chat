import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Realtime DB যোগ করা হয়েছে
import 'package:flutter/foundation.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtime = FirebaseDatabase.instance; // Realtime DB ইনস্ট্যান্স
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১️⃣ রুমের মেইন প্রোফাইল (Firestore-এ থাকবে)
  Future<void> updateRoomFullData({
    required String roomId,
    required String roomName,
    required String roomImage,
    required bool isLocked,
    required String wallpaper,
    required int followers,
    required int totalDiamonds,
    String? uID,
    String? ownerName,
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
        'ownerId': uID ?? "",
        'uID': uID ?? "",
        'ownerName': ownerName ?? 'Owner',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Room Update Error: $e");
    }
  }

  // ২️⃣ সিটে বসা (ল্যাগ কমাতে এটাকে Realtime Database-এ নিয়ে গেলাম)
  Future<void> updateSeatData({
    required String roomId,
    required int seatIndex,
    required String uName,
    required String uImage,
    required bool isOccupied,
    String? uIDShow, // আপনার ৬ ডিজিটের আইডি
  }) async {
    final User? user = _auth.currentUser;
    if (roomId.isEmpty || user == null) return;

    try {
      // Realtime Database রেফারেন্স - যা আপনার UI-এর সাথে মিলবে
      DatabaseReference seatRef = _realtime.ref('rooms/$roomId/seats/$seatIndex');

      if (isOccupied) {
        await seatRef.set({
          'userName': uName,
          'userImage': uImage,
          'isOccupied': true,
          'uID': uIDShow ?? "", 
          'authID': user.uid,
          'isMicOn': true,
          'isTalking': false,
          'at': ServerValue.timestamp,
        });
      } else {
        await seatRef.remove(); // সিট খালি হলে ডাটা মুছে ফেলবে, ল্যাগ হবে না
      }
      debugPrint("✅ Seat $seatIndex Updated in Realtime DB");
    } catch (e) {
      debugPrint("❌ Seat Update Error: $e");
    }
  }

  // ৩️⃣ ডায়মন্ড ব্যালেন্স স্ট্রিম (Firestore)
  Stream<DocumentSnapshot>? getUserDiamonds(String useruID) {
    if (useruID.isEmpty) return null;
    return _firestore.collection('users').doc(useruID).snapshots();
  }

  // ৪️⃣ গিফট লজিক (Firestore)
  Future<bool> sendGift({
    required String roomId,
    required int giftValue,
    required String senderuID,
    required String receiveruID,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(senderuID).get();
      if (!userDoc.exists) return false;
      
      final int currentBalance = userDoc.data()?['diamonds'] ?? 0;

      if (currentBalance >= giftValue) {
        WriteBatch batch = _firestore.batch();
        batch.update(_firestore.collection('users').doc(senderuID), {'diamonds': FieldValue.increment(-giftValue)});
        batch.update(_firestore.collection('rooms').doc(roomId), {'totalDiamonds': FieldValue.increment(giftValue)});

        if (receiveruID.isNotEmpty && receiveruID != "null") {
          batch.update(_firestore.collection('users').doc(receiveruID), {'receivedDiamonds': FieldValue.increment(giftValue)});
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

  // ৫️⃣ রুম লিভ (Firestore)
  Future<void> leaveRoom(String useruID) async {
    if (useruID.isEmpty) return;
    try {
      await _firestore.collection('users').doc(useruID).update({'currentRoomId': ""});
    } catch (e) {
      debugPrint("❌ Leave Error: $e");
    }
  }
}