import 'package:cloud_firestore/cloud_firestore.dart'; // এই লাইনটি মিসিং ছিল
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeatSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১. 🔥 সিটে বসার এবং ডাটা আপডেট করার ফাংশন
  Future<void> updateSeatLive({
    required String roomId,
    required int index,
    required String name,
    required String image,
    required String status,
    required bool isOccupied,
    String? uID, 
  }) async {
    final User? currentUser = _auth.currentUser;
    if (roomId.isEmpty || currentUser == null) return;

    try {
      await _db.ref('rooms/$roomId/seats/$index').set({
        'userName': name,
        'profilePic': image,
        'status': status,
        'isOccupied': isOccupied,
        'isMicOn': (status == "occupied"),
        'userId': currentUser.uid,
        'uID': uID ?? "",
        'isTalking': false,
        'giftCount': 0,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      // Catch block left empty to safely ignore error without printing
    }
  }

  // ২. 🚀 সিট খালি করার ফাংশন
  Future<void> clearSeatLive({required String roomId, required int index}) async {
    if (roomId.isEmpty) return;
    try {
      await _db.ref('rooms/$roomId/seats/$index').remove();
    } catch (e) {
      // Catch block left empty to safely ignore error without printing
    }
  }

  // ৩. 👤 ইউজারের তথ্য পাওয়ার রাস্তা
  Future<Map<String, dynamic>?> getUserData(String uID) async {
     // এখানে Firestore ব্যবহার করা হয়েছে, তাই উপরের ইমপোর্টটি জরুরি
     final doc = await FirebaseFirestore.instance.collection('users').doc(uID).get();
     return doc.data();
  }
}