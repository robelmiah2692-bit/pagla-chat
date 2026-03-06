import 'package:cloud_firestore/cloud_firestore.dart';

class SeatSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 সিটে বসার সাথে সাথে ডাটাবেস আপডেট করা যাতে সবাই দেখতে পায়
  Future<void> updateSeatLive({
    required String roomId,
    required int index,
    required String name,
    required String image,
    required String status, // "calling" অথবা "occupied"
    required bool isOccupied,
  }) async {
    await _db.collection('rooms').doc(roomId).collection('seats').doc(index.toString()).set({
      'userName': name,
      'userImage': image,
      'status': status,
      'isOccupied': isOccupied,
      'isMicOn': (status == "occupied"), // শুধু occupied হলে মাইক নীল হবে
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
