import 'package:firebase_database/firebase_database.dart';

class RoomSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ১. সিটে বসার তথ্য আপডেট (ফ্রেম এবং রিপেল ডাটা সহ)
  Future<void> sitOnChair(String roomId, int seatIndex, Map<String, dynamic> userData) async {
    final String userUid = userData['uid'] ?? userData['uID'] ?? "";

    await _db.ref('rooms/$roomId/seats/seat_$seatIndex').set({
      'uid': userUid,
      'uID': userUid, // মালিক চেনার জন্য ডাবল চেক
      'name': userData['name'],
      'avatar': userData['avatar'],
      
      // গুরুত্বপূর্ণ: ফ্রেম এবং রিপেল ইফেক্ট দেখানোর জন্য এই ডাটাগুলো লাগবে
      'frameUrl': userData['frameUrl'] ?? "", // ইউজারের প্রোফাইল ফ্রেম
      'rippleUrl': userData['rippleUrl'] ?? "", // কথা বলার সময় যে রিপেল ইফেক্ট হয়
      'isOccupied': true,
      'timestamp': ServerValue.timestamp,
    });
  }

  // ২. রুমের সিটগুলোর অবস্থা শোনা
  Stream<DatabaseEvent> getSeatsStream(String roomId) {
    return _db.ref('rooms/$roomId/seats').onValue;
  }

  // ৩. চ্যাট মেসেজ পাঠানো (এখানেও ফ্রেম ডাটা পাঠাতে পারেন যদি চ্যাটে ফ্রেম লাগে)
  Future<void> sendChatMessage(String roomId, Map<String, dynamic> messageData) async {
    final String senderUid = messageData['uid'] ?? messageData['uID'] ?? "";
    
    await _db.ref('rooms/$roomId/chats').push().set({
      ...messageData,
      'uid': senderUid,
      'uID': senderUid,
      'timestamp': ServerValue.timestamp,
    });
  }

  // ৪. চ্যাট মেসেজ রিড করা
  Stream<List<Map<dynamic, dynamic>>> getChatStream(String roomId) {
    return _db.ref('rooms/$roomId/chats').limitToLast(20).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<Map<dynamic, dynamic>> messageList = [];
      data.forEach((key, value) {
        messageList.add(Map<dynamic, dynamic>.from(value as Map));
      });
      
      messageList.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
      return messageList;
    });
  }
  
  // ৫. সিট থেকে নেমে যাওয়া (Data Clear করা)
  Future<void> leaveChair(String roomId, int seatIndex) async {
    await _db.ref('rooms/$roomId/seats/seat_$seatIndex').set({
      'isOccupied': false,
      'uid': "",
      'uID': "",
      'name': "Empty",
    });
  }
}
