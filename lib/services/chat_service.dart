import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১. মেসেজ পাঠানোর লজিক
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    // মেসেজ মডেল
    Map<String, dynamic> newMessage = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    };

    // দুই ইউজারের আইডি মিলিয়ে ইউনিক চ্যাট রুম আইডি তৈরি
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); 
    String chatRoomId = ids.join("_");

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage);
  }

  // ২. মেসেজ রিসিভ করার স্ট্রিম (টাইপ সেফটি সহ)
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
