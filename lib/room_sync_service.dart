import 'package:firebase_database/firebase_database.dart';

class RoomSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ১. সিটে বসার তথ্য আপডেট (Realtime Database ব্যবহার করে ল্যাগ কমানো হয়েছে)
  Future<void> sitOnChair(String roomId, int seatIndex, Map<String, dynamic> userData) async {
    try {
      final String authUID = userData['authUID'] ?? userData['uID'] ?? ""; 
      final String fixeduID = userData['uID'] ?? "";

      await _db.ref('rooms/$roomId/seats/$seatIndex').set({
        'userId': authUID,          // লম্বা Auth uID
        'uID': fixeduID,            // ৬-ডিজিটের ইউনিক ID
        'name': userData['name'] ?? userData['userName'] ?? "User", 
        'profilePic': userData['profilePic'] ?? userData['avatar'] ?? "", 
        
        // ফ্রেম এবং রিপেল ডাটা
        'frameUrl': userData['frameUrl'] ?? "", 
        'rippleUrl': userData['rippleUrl'] ?? "", 
        
        'isOccupied': true,
        'isMicOn': true,
        'isTalking': false,
        'giftCount': 0,
        'timestamp': ServerValue.timestamp,
      });
      print("✅ Sat on seat $seatIndex");
    } catch (e) {
      print("❌ Sit Error: $e");
    }
  }

  // ২. রুমের সিটগুলোর অবস্থা শোনা
  Stream<DatabaseEvent> getSeatsStream(String roomId) {
    return _db.ref('rooms/$roomId/seats').onValue;
  }

  // ৩. চ্যাট মেসেজ পাঠানো
  Future<void> sendChatMessage(String roomId, Map<String, dynamic> messageData) async {
    try {
      final String senderauthUID = messageData['authUID'] ?? messageData['uID'] ?? "";
      final String senderFixeduID = messageData['uID'] ?? "";
      
      await _db.ref('rooms/$roomId/chats').push().set({
        ...messageData,
        'userId': senderauthUID,
        'uID': senderFixeduID,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print("❌ Chat Send Error: $e");
    }
  }

  // ৪. চ্যাট মেসেজ রিড করা (টাইপ সেফটি ও পারফরম্যান্স ফিক্স)
  Stream<List<Map<dynamic, dynamic>>> getChatStream(String roomId) {
    return _db.ref('rooms/$roomId/chats').limitToLast(25).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<Map<dynamic, dynamic>> messageList = [];
      data.forEach((key, value) {
        if (value is Map) {
          var msg = Map<dynamic, dynamic>.from(value);
          msg['key'] = key;
          messageList.add(msg);
        }
      });
      
      messageList.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
      return messageList;
    });
  }
  
  // ৫. সিট থেকে নেমে যাওয়া (সম্পূর্ণ ক্লিয়ার)
  Future<void> leaveChair(String roomId, int seatIndex) async {
    try {
      await _db.ref('rooms/$roomId/seats/$seatIndex').remove();
      print("✅ Left seat $seatIndex");
    } catch (e) {
      print("❌ Leave Chair Error: $e");
    }
  }

  // ৬. মাইক স্ট্যাটাস আপডেট
  Future<void> updateMicStatus(String roomId, int seatIndex, bool isMicOn) async {
    try {
      await _db.ref('rooms/$roomId/seats/$seatIndex').update({
        'isMicOn': isMicOn,
      });
    } catch (e) {
      print("❌ Mic Status Error: $e");
    }
  }
}