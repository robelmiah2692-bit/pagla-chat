import 'package:firebase_database/firebase_database.dart';

class RoomSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ১. সিটে বসার তথ্য আপডেট (Realtime Database ব্যবহার করে ল্যাগ কমানো হয়েছে)
  Future<void> sitOnChair(String roomId, int seatIndex, Map<String, dynamic> userData) async {
    try {
      // আপনার ৬-ডিজিটের ইউনিক আইডি এবং লম্বা আইডি আলাদা করা হলো
      final String authuID = userData['authuID'] ?? userData['uID'] ?? ""; 
      final String fixeduID = userData['uID'] ?? "";

      // সরাসরি রেফারেন্স ব্যবহার করে দ্রুত ডাটা সেট করা
      await _db.ref('rooms/$roomId/seats/$seatIndex').set({
        'userId': authuID,        // লম্বা Auth uID
        'uID': fixeduID,          // আপনার ৬-ডিজিটের ইউনিক ID (৯৭০৩২১ টাইপ)
        'name': userData['name'] ?? userData['userName'] ?? "User", // name ফিল্ডটি সিঙ্ক করা হলো
        'profilePic': userData['profilePic'] ?? userData['avatar'] ?? "", 
        
        // ফ্রেম এবং রিপেল ডাটা
        'frameUrl': userData['frameUrl'] ?? "", 
        'rippleUrl': userData['rippleUrl'] ?? "", 
        
        'isOccupied': true,
        'isMicOn': true,
        'isTalking': false,
        'giftCount': 0,
        'timestamp': ServerValue.timestamp, // সার্ভার টাইমস্ট্যাম্প
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
      final String senderAuthuID = messageData['authuID'] ?? messageData['uID'] ?? "";
      final String senderFixeduID = messageData['uID'] ?? "";
      
      await _db.ref('rooms/$roomId/chats').push().set({
        ...messageData,
        'userId': senderAuthuID,
        'uID': senderFixeduID,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print("❌ Chat Send Error: $e");
    }
  }

  // ৪. চ্যাট মেসেজ রিড করা (পারফরম্যান্স ফিক্স)
  Stream<List<Map<dynamic, dynamic>>> getChatStream(String roomId) {
    return _db.ref('rooms/$roomId/chats').limitToLast(25).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<Map<dynamic, dynamic>> messageList = [];
      data.forEach((key, value) {
        var msg = Map<dynamic, dynamic>.from(value as Map);
        msg['key'] = key; // মেসেজ ডিলিট করার সুবিধার জন্য কি রাখা হলো
        messageList.add(msg);
      });
      
      messageList.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
      return messageList;
    });
  }
  
  // ৫. সিট থেকে নেমে যাওয়া (সম্পূর্ণ ক্লিয়ার)
  Future<void> leaveChair(String roomId, int seatIndex) async {
    try {
      // ডাটাবেস থেকে ওই সিটের ডাটা সম্পূর্ণ রিমুভ করা হলো
      await _db.ref('rooms/$roomId/seats/$seatIndex').remove();
      print("✅ Left seat $seatIndex");
    } catch (e) {
      print("❌ Leave Chair Error: $e");
    }
  }

  // ৬. মাইক স্ট্যাটাস আপডেট (কথা বলার সময় যেন সাথে সাথে সিঙ্ক হয়)
  Future<void> updateMicStatus(String roomId, int seatIndex, bool isMicOn) async {
    await _db.ref('rooms/$roomId/seats/$seatIndex').update({
      'isMicOn': isMicOn,
    });
  }
}