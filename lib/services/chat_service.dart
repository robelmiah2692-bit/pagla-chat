import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagla_chat/services/notification_service.dart'; // আপনার প্রোজেক্টের সঠিক পাথটি নিশ্চিত করুন

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১. মেসেজ পাঠানোর লজিক (নোটিফিকেশন সহ)
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    // মেসেজ ডাটা
    Map<String, dynamic> newMessage = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': false, // মেসেজটি পড়া হয়েছে কি না ট্র্যাকিংয়ের জন্য
    };

    // ইউনিক চ্যাট রুম আইডি তৈরি (A_B ফরম্যাট)
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); 
    String chatRoomId = ids.join("_");

    try {
      // ১. ডাটাবেসে মেসেজ সেভ করা
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage);

      // ২. নোটিফিকেশন পাঠানোর লজিক
      // যাকে মেসেজ পাঠাচ্ছেন তার ডাটা থেকে fcmToken এবং নিজের নাম নেওয়া
      DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      DocumentSnapshot senderDoc = await _firestore.collection('users').doc(currentUserId).get();

      if (receiverDoc.exists) {
        String? token = receiverDoc.get('fcmToken');
        String senderName = senderDoc.get('name') ?? "নতুন মেসেজ";

        if (token != null && token.isNotEmpty) {
          // ✅ আপনার আপডেট করা NotificationService কল করা হচ্ছে
          await NotificationService.sendNotificationToUser(
            receiverToken: token, 
            title: senderName, 
            body: message,
            extraData: {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'senderId': currentUserId, // নোটিফিকেশনে ক্লিক করলে যেন আপনার চ্যাট ওপেন হয়
              'route': '/chat',
            },
          );
        }
      }
    } catch (e) {
      print("❌ Chat Service Error: $e");
    }
  }

  // ২. মেসেজ রিসিভ করার রিয়েল-টাইম স্ট্রিম
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
