import 'package:cloud_firestore/cloud_firestore.dart';

class SeatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 সিটে বসার এবং ডাটাবেস আপডেট করার ফাংশন
  Future<void> updateSeatStatus({
    required String roomId,
    required int seatIndex,
    required String uName,
    required String uImage,
    required bool isOccupied,
    String status = "occupied",
  }) async {
    try {
      await _db.collection('rooms').doc(roomId).collection('seats').doc(seatIndex.toString()).set({
        'userName': uName,
        'userImage': uImage,
        'isOccupied': isOccupied,
        'isMicOn': isOccupied,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Seat Update Error: $e");
    }
  }

  // 🔥 সিট খালি করার ফাংশন (এটি যোগ করলে আপনার সব সিটে ছবি থেকে যাওয়ার সমস্যা দূর হবে)
  Future<void> clearSeat({required String roomId, required int seatIndex}) async {
    try {
      await _db
          .collection('rooms')
          .doc(roomId)
          .collection('seats')
          .doc(seatIndex.toString())
          .delete(); // সরাসরি ডিলিট করে দিলে সিট পুরোপুরি খালি হয়ে যাবে
    } catch (e) {
      print("Seat Clear Error: $e");
    }
  }
}
