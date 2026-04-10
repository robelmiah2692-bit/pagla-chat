import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeatSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১. 🔥 সিটে বসার এবং ডাটা আপডেট করার ফাংশন (ফায়ারবেসের সাথে মিল রেখে)
  Future<void> updateSeatLive({
    required String roomId,
    required int index,
    required String name,
    required String image,
    required String status,
    required bool isOccupied,
    String? uID, // ইউজারের সেই ৬-ডিজিটের আইডি (যেমন: "153530")
  }) async {
    final User? currentUser = _auth.currentUser;
    if (roomId.isEmpty || currentUser == null) return;

    try {
      // আপনার স্ক্রিনশট অনুযায়ী রাস্তা: rooms -> roomId -> seats -> index
      await _db
          .collection('rooms')
          .doc(roomId)
          .collection('seats')
          .doc(index.toString())
          .set({
        'name': name,            // ডাটাবেসের 'name' ফিল্ডের সাথে মিলানো হলো
        'profilePic': image,     // ডাটাবেসের 'profilePic' ফিল্ডের সাথে মিলানো হলো
        'status': status,
        'isOccupied': isOccupied,
        'isMicOn': (status == "occupied"),
        'authUID': currentUser.uid, // ফায়ারবেস অথেন্টিকেশন আইডি
        'uID': uID ?? "",           // আপনার মালিকের চেনার আইডি (যেমন: 153530)
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print("✅ Seat $index updated correctly with Firebase fields.");
    } catch (e) {
      print("❌ Seat Update Error: $e");
    }
  }

  // ২. 🚀 সিট খালি করার ফাংশন
  Future<void> clearSeatLive({required String roomId, required int index}) async {
    if (roomId.isEmpty) return;
    
    try {
      // সিট খালি হলে সরাসরি ডকুমেন্ট ডিলিট করা হবে
      await _db
          .collection('rooms')
          .doc(roomId)
          .collection('seats')
          .doc(index.toString())
          .delete();
          
      print("🗑️ Seat $index cleared from Firebase.");
    } catch (e) {
      print("❌ Seat Clear Error: $e");
    }
  }

  // ৩. 👤 ইউজারের তথ্য সরাসরি 'users' কালেকশন থেকে পাওয়ার রাস্তা
  // আপনার ডাটাবেস রাস্তা: users -> 153530
  DocumentReference getUserReference(String uID) {
    return _db.collection('users').doc(uID);
  }
}
