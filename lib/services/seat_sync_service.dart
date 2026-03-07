import 'package:cloud_firestore/cloud_firestore.dart';

class SeatSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ১. 🔥 সিটে বসার এবং ডাটা আপডেট করার ফাংশন (Calling বা Occupied এর জন্য)
  Future<void> updateSeatLive({
    required String roomId,
    required int index,
    required String name,
    required String image,
    required String status,
    required bool isOccupied,
  }) async {
    try {
      await _db.collection('rooms').doc(roomId).collection('seats').doc(index.toString()).set({
        'userName': name,
        'userImage': image,
        'status': status,
        'isOccupied': isOccupied,
        'isMicOn': (status == "occupied"),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Seat Update Error: $e");
    }
  }

  // ২. 🚀 মিসিং পার্ট: সিট খালি করার ফাংশন (এটি না থাকলে সিটে ছবি ঝুলে থাকবে)
  Future<void> clearSeatLive({required String roomId, required int index}) async {
    try {
      // সিটের ডকুমেন্টটি সরাসরি ডিলিট করে দেওয়া সবথেকে নিরাপদ সমাধান
      await _db
          .collection('rooms')
          .doc(roomId)
          .collection('seats')
          .doc(index.toString())
          .delete();
      print("Seat $index cleaned from database.");
    } catch (e) {
      print("Seat Clear Error: $e");
    }
  }
}
