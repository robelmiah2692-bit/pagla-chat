import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ ১. রুমের সব ডাটা (নাম, ছবি, লক, ওয়ালপেপার) একসাথে সেভ রাখা
  Future<void> updateRoomFullData({
    required String roomId,
    required String roomName,
    required String roomImage,
    required bool isLocked,
    required String wallpaper,
    required int followers,
    required int totalDiamonds, // টপ রুম র‍্যাঙ্কিংয়ের জন্য
  }) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      await _firestore.collection('rooms').doc(roomId).set({
        'roomId': roomId,
        'roomName': roomName,
        'roomImage': roomImage,
        'isLocked': isLocked,
        'wallpaper': wallpaper,
        'followerCount': followers,
        'totalDiamonds': totalDiamonds, // ডায়মন্ড অনুযায়ী টপ রুম লিস্ট হবে
        'adminId': uid,
        'isLive': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print("✅ Room Full Data Synced!");
    } catch (e) {
      print("❌ Room Update Error: $e");
    }
  }

  // ✅ ২. সিটে বসার সাথে সাথে প্রোফাইল ছবি ও নাম ডাটাবেসে সেভ করা
  Future<void> updateSeatData({
    required String roomId,
    required int seatIndex,
    required String uName,
    required String uImage,
    required bool isOccupied,
  }) async {
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
      print("✅ Seat $seatIndex updated with profile!");
    } catch (e) {
      print("❌ Seat Update Error: $e");
    }
  }

  // ✅ ৩. ডায়মন্ড কাউন্ট আপডেট (টপ রুমের জন্য)
  Future<void> updateDiamondCount(String roomId, int newDiamonds) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'totalDiamonds': FieldValue.increment(newDiamonds),
    });
  }

  // ✅ ৪. রুম থেকে বের হলে ইউজার প্রোফাইল ক্লিন করা
  Future<void> leaveRoom(String roomId) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).update({
      'currentRoomId': "",
    });
  }
}
