import 'package:firebase_database/firebase_database.dart';

class RoomSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ১. সিটে বসার তথ্য ডাটাবেজে আপডেট করা (আপনার রুল: বসার পর কলিং হবে)
  Future<void> sitOnChair(String roomId, int seatIndex, Map<String, dynamic> userData) async {
    await _db.ref('rooms/$roomId/seats/seat_$seatIndex').set({
      'uid': userData['uid'],
      'name': userData['name'],
      'avatar': userData['avatar'],
      'isOccupied': true,
      'timestamp': ServerValue.timestamp,
    });
  }

  // ২. রুমের সিটগুলোর অবস্থা শোনা (Stream)
  // এটি ব্যবহার করলে একজন বসলে সবার স্ক্রিনে আপডেট হবে
  Stream<DatabaseEvent> getSeatsStream(String roomId) {
    return _db.ref('rooms/$roomId/seats').onValue;
  }

  // ৩. চ্যাট মেসেজ পাঠানো
  Future<void> sendChatMessage(String roomId, Map<String, dynamic> messageData) async {
    await _db.ref('rooms/$roomId/chats').push().set({
      ...messageData,
      'timestamp': ServerValue.timestamp,
    });
  }

  // ৪. চ্যাট বক্সের মেসেজ শোনা (সবাই যেন মেসেজ দেখে)
  Stream<DatabaseEvent> getChatStream(String roomId) {
    return _db.ref('rooms/$roomId/chats').limitToLast(20).onValue;
  }
}
