import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ ১. নির্দিষ্ট Room ID অনুযায়ী ডাটাবেসে সেভ করা
  Future<void> createRoom(String roomId, String roomName, String roomType) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      // এখানে .doc(uid) এর বদলে .doc(roomId) ব্যবহার করা হয়েছে
      await _firestore.collection('rooms').doc(roomId).set({
        'roomId': roomId,
        'roomName': roomName,
        'roomType': roomType,
        'adminId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isLive': true,
      }, SetOptions(merge: true)); // merge: true দিলে ডাটা হারাবে না
      
      // ইউজারের প্রোফাইলে আপডেট
      await _firestore.collection('users').doc(uid).update({
        'currentRoomId': roomId,
        'currentRoomName': roomName,
      });
      
      print("✅ Room Saved Successfully for ID: $roomId");
    } catch (e) {
      print("❌ Room Save Error: $e");
    }
  }

  // ✅ ২. ইউজার সিটে বসলে বা জয়েন করলে আপডেট
  Future<void> joinRoom(String roomId, String userName) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'activeUsers': FieldValue.arrayUnion([
          {
            'uid': uid, 
            'name': userName, 
            'joinedAt': DateTime.now().toIso8601String(),
          }
        ])
      });
    } catch (e) {
      print("❌ Join Room Error: $e");
    }
  }

  // ✅ ৩. রুম থেকে বের হয়ে গেলে ডাটা ক্লিয়ার করা
  Future<void> leaveRoom(String roomId) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      // ইউজার প্রোফাইল আপডেট
      await _firestore.collection('users').doc(uid).update({
        'currentRoomId': "",
        'currentRoomName': "",
      });
      print("✅ Left Room successfully");
    } catch (e) {
      print("❌ Leave Room Error: $e");
    }
  }
}
