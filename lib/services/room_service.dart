import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1️⃣ রুম ডাটা সেভ (Web এর জন্য Map কাস্টিং নিরাপদ করা হয়েছে)
  Future<void> updateRoomFullData({
    required String roomId,
    required String roomName,
    required String roomImage,
    required bool isLocked,
    required String wallpaper,
    required int followers,
    required int totalDiamonds,
  }) async {
    final String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty || roomId.isEmpty) return;

    try {
      await _firestore.collection('rooms').doc(roomId).set({
        'roomId': roomId,
        'roomName': roomName,
        'roomImage': roomImage,
        'isLocked': isLocked,
        'wallpaper': wallpaper,
        'followerCount': followers,
        'totalDiamonds': totalDiamonds,
        'adminId': uid,
        'isLive': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ Room Synced");
    } catch (e) {
      print("❌ Room Update Error: $e");
    }
  }

  // 2️⃣ সিট আপডেট (Dot notation 'seats.index' ওয়েবে পারফেক্ট কাজ করে)
  Future<void> updateSeatData({
    required String roomId,
    required int seatIndex,
    required String uName,
    required String uImage,
    required bool isOccupied,
  }) async {
    if (roomId.isEmpty) return;
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'seats.$seatIndex': {
          'userName': uName,
          'userImage': uImage,
          'isOccupied': isOccupied,
          'uid': _auth.currentUser?.uid,
          'at': DateTime.now().toIso8601String(),
        }
      });
    } catch (e) {
      print("❌ Seat Update Error: $e");
    }
  }

  // 3️⃣ ইউজার ডায়মন্ড স্ট্রিম
  Stream<DocumentSnapshot> getUserDiamonds() {
    final String uid = _auth.currentUser?.uid ?? "";
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // 4️⃣ গিফট লজিক (ওয়েবে ডাটা রিড করার সময় টাইপ কাস্টিং ফিক্স করা হয়েছে)
  Future<bool> sendGift({
    required String roomId,
    required int giftValue,
    required String receiverId,
  }) async {
    final String senderUid = _auth.currentUser?.uid ?? "";
    if (senderUid.isEmpty) return false;

    try {
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(senderUid).get();
      
      // ওয়েবে ডাটা রিড করার নিরাপদ উপায়
      final Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      final int currentBalance = userData?['diamonds'] ?? 0;

      if (currentBalance >= giftValue) {
        // ট্রানজ্যাকশন ছাড়াই আপডেট (ওয়েবে এটি দ্রুত কাজ করে)
        await _firestore.collection('users').doc(senderUid).update({
          'diamonds': FieldValue.increment(-giftValue),
        });

        await _firestore.collection('rooms').doc(roomId).update({
          'totalDiamonds': FieldValue.increment(giftValue),
        });

        if (receiverId.isNotEmpty) {
          await _firestore.collection('users').doc(receiverId).update({
            'receivedDiamonds': FieldValue.increment(giftValue),
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Gift Error: $e");
      return false;
    }
  }

  // 5️⃣ রুম লিভ করা
  Future<void> leaveRoom(String roomId) async {
    final String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'currentRoomId': "",
      });
    } catch (e) {
      print("❌ Leave Error: $e");
    }
  }
}
