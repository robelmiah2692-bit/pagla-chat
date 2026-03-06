import 'package:cloud_firestore/cloud_firestore.dart';

class SeatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 সিটে বসার এবং ডাটাবেস আপডেট করার মেইন ফাংশন
  Future<void> updateSeatStatus({
    required String roomId,
    required int seatIndex,
    required String uName,
    required String uImage,
    required bool isOccupied,
    String status = "occupied",
  }) async {
    try {
      // এই পাথটি একদম সঠিক হতে হবে যাতে সবাই দেখতে পায়
      await _db.collection('rooms').doc(roomId).collection('seats').doc(seatIndex.toString()).set({
        'userName': uName,
        'userImage': uImage,
        'isOccupied': isOccupied,
        'isMicOn': isOccupied, // বসার সাথে সাথে মাইক অন
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Seat Update Error: $e");
    }
  }
}
