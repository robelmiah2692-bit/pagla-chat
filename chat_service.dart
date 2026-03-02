import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  // ১. মেসেজ পাঠানো (পার্মানেন্টলি সেভ হবে)
  Future<void> sendMessage(String receiverId, String message) async {
    if (_currentUid == null || message.trim().isEmpty) return;

    // চ্যাট আইডি তৈরি (দুই ইউজারের আইডি মিলিয়ে একটি ইউনিক আইডি)
    List<String> ids = [_currentUid!, receiverId];
    ids.sort(); 
    String chatRoomId = ids.join("_");

    await _db.collection('chat_rooms').doc(chatRoomId).collection('messages').add({
      'senderId': _currentUid,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(), // সার্ভার টাইম অনুযায়ী সেভ হবে
    });
  }

  // ২. রিয়েল-টাইম মেসেজ পড়া (Inbox)
  Stream<QuerySnapshot> getMessages(String receiverId) {
    List<String> ids = [_currentUid!, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
