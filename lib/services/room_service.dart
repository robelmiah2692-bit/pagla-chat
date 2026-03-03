import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১. নতুন রুম ডাটাবেসে সেইভ করা
  Future<void> createRoom(String roomName, String roomType) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      await _firestore.collection('rooms').doc(uid).set({
        'roomName': roomName,
        'roomType': roomType,
        'adminId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'activeUsers': [],
        'isLive': true,
      });
      
      // ইউজারের প্রোফাইলেও আপডেট করে দেওয়া যে সে এখন এই রুমে আছে
      await _firestore.collection('users').doc(uid).update({
        'currentRoom': roomName,
      });
    } catch (e) {
      print("Room Save Error: $e");
    }
  }

  // ২. ইউজার রুমে ঢুকলে বা সিটে বসলে ডাটা আপডেট
  Future<void> joinRoom(String roomId, String userName) async {
    String uid = _auth.currentUser?.uid ?? "";
    
    await _firestore.collection('rooms').doc(roomId).update({
      'activeUsers': FieldValue.arrayUnion([
        {'uid': uid, 'name': userName, 'joinedAt': DateTime.now().toString()}
      ])
    });
  }

  // ৩. রুম থেকে বের হয়ে গেলে ডাটা ক্লিয়ার করা
  Future<void> leaveRoom(String roomId) async {
    String uid = _auth.currentUser?.uid ?? "";
    
    // ইউজার লিস্ট থেকে রিমুভ করা
    await _firestore.collection('rooms').doc(roomId).update({
      'activeUsers': FieldValue.arrayRemove([uid]) // এটি আপনার লজিক অনুযায়ী ম্যাপ রিমুভ করতে হবে
    });

    await _firestore.collection('users').doc(uid).update({
      'currentRoom': "",
    });
  }
}
