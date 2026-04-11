import 'package:firebase_database/firebase_database.dart'; // Firestore এর বদলে Realtime Database
import 'package:firebase_auth/firebase_auth.dart';

class SeatSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১. 🔥 সিটে বসার এবং ডাটা আপডেট করার ফাংশন (Realtime Database এর সঠিক রাস্তায়)
  Future<void> updateSeatLive({
    required String roomId,
    required int index,
    required String name,
    required String image,
    required String status,
    required bool isOccupied,
    String? uID, // আপনার ৬-ডিজিটের আইডি
  }) async {
    final User? currentUser = _auth.currentUser;
    if (roomId.isEmpty || currentUser == null) return;

    try {
      // সঠিক রাস্তা: rooms -> roomId -> seats -> index (Realtime Database)
      await _db.ref('rooms/$roomId/seats/$index').set({
        'userName': name,           // voice_room এর সাথে মিল রেখে
        'profilePic': image,        // আপনার স্ক্রিনশট ও প্রোফাইল ডাটা অনুযায়ী
        'status': status,
        'isOccupied': isOccupied,
        'isMicOn': (status == "occupied"),
        'userId': currentUser.uid,  // লম্বা Auth ID
        'uId': uID ?? "",           // ৬-ডিজিটের ID
        'isTalking': false,
        'giftCount': 0,
        'timestamp': ServerValue.timestamp,
      });
      
      print("✅ Seat $index updated in Realtime Database.");
    } catch (e) {
      print("❌ Seat Update Error: $e");
    }
  }

  // ২. 🚀 সিট খালি করার ফাংশন
  Future<void> clearSeatLive({required String roomId, required int index}) async {
    if (roomId.isEmpty) return;
    
    try {
      // Realtime Database থেকে সিট রিমুভ করা
      await _db.ref('rooms/$roomId/seats/$index').remove();
      print("🗑️ Seat $index cleared from Realtime Database.");
    } catch (e) {
      print("❌ Seat Clear Error: $e");
    }
  }

  // ৩. 👤 ইউজারের তথ্য পাওয়ার রাস্তা (এটি Firestore-এ থাকবে কারণ প্রোফাইল সেখানেই থাকে)
  // আপনার রাস্তা: users -> ৬-ডিজিটের uID
  Future<Map<String, dynamic>?> getUserData(String uID) async {
     final doc = await FirebaseFirestore.instance.collection('users').doc(uID).get();
     return doc.data();
  }
}
