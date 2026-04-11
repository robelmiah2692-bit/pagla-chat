import 'package:firebase_database/firebase_database.dart';

class RoomSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ১. সিটে বসার তথ্য আপডেট (আপনার ডাটাবেস ফিল্ড 'profilePic' অনুযায়ী ফিক্সড)
  Future<void> sitOnChair(String roomId, int seatIndex, Map<String, dynamic> userData) async {
    // আপনার ৬-ডিজিটের ইউনিক আইডি এবং লম্বা আইডি আলাদা করা হলো
    final String authUid = userData['authUid'] ?? userData['uid'] ?? ""; 
    final String fixedUid = userData['uID'] ?? userData['uid'] ?? "";

    // voice_room.dart এর লিসেনার যেন চিনতে পারে তাই সরাসরি ইনডেক্স ব্যবহার করা হয়েছে
    await _db.ref('rooms/$roomId/seats/$seatIndex').set({
      'userId': authUid,       // লম্বা Auth UID
      'uId': fixedUid,         // আপনার ৬-ডিজিটের ইউনিক ID (৯৭০৩২১ টাইপ)
      'userName': userData['name'] ?? userData['userName'] ?? "User",
      'profilePic': userData['profilePic'] ?? userData['avatar'] ?? "", // আপনার স্ক্রিনশট অনুযায়ী ফিক্সড
      
      // ফ্রেম এবং রিপেল ডাটা
      'frameUrl': userData['frameUrl'] ?? "", 
      'rippleUrl': userData['rippleUrl'] ?? "", 
      
      'isOccupied': true,
      'status': 'occupied',
      'isMicOn': true,
      'isTalking': false,
      'giftCount': 0,
      'timestamp': ServerValue.timestamp,
    });
  }

  // ২. রুমের সিটগুলোর অবস্থা শোনা
  Stream<DatabaseEvent> getSeatsStream(String roomId) {
    return _db.ref('rooms/$roomId/seats').onValue;
  }

  // ৩. চ্যাট মেসেজ পাঠানো
  Future<void> sendChatMessage(String roomId, Map<String, dynamic> messageData) async {
    final String senderAuthUid = messageData['authUid'] ?? messageData['uid'] ?? "";
    final String senderFixedUid = messageData['uID'] ?? messageData['uid'] ?? "";
    
    await _db.ref('rooms/$roomId/chats').push().set({
      ...messageData,
      'userId': senderAuthUid,
      'uId': senderFixedUid,
      'profilePic': messageData['profilePic'] ?? "", // চ্যাটেও ছবির ফিল্ড ঠিক করা হলো
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
  
  // ৫. সিট থেকে নেমে যাওয়া (Data Clear করা)
  Future<void> leaveChair(String roomId, int seatIndex) async {
    // সিট খালি করার সময় পুরো নোড রিমুভ করে দেওয়া সবচেয়ে নিরাপদ
    await _db.ref('rooms/$roomId/seats/$seatIndex').remove();
  }
}
