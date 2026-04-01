import 'package:firebase_database/firebase_database.dart';

class RoomSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ১. সিটে বসার তথ্য ডাটাবেজে আপডেট করা (বসার পর কলিং হবে)
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

  // ৪. চ্যাট বক্সের মেসেজ শোনা (সবাই যেন মেসেজ দেখতে পায়)
  // এখানে শুধু .map() যোগ করা হয়েছে যাতে ডেটা লিস্ট আকারে সবার কাছে পৌঁছায়
  Stream<List<Map<dynamic, dynamic>>> getChatStream(String roomId) {
    return _db.ref('rooms/$roomId/chats').limitToLast(20).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<Map<dynamic, dynamic>> messageList = [];
      data.forEach((key, value) {
        messageList.add(Map<dynamic, dynamic>.from(value));
      });
      
      // সময় অনুযায়ী সাজানো
      messageList.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
      return messageList;
    });
  }
}
