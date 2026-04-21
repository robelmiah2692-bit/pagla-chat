import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// আপনার প্রোজেক্টের সঠিক পাথটি নিশ্চিত করুন
import 'package:pagla_chat/services/notification_service.dart'; 

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ১. মেসেজ পাঠানোর লজিক (ফায়ারবেস স্ট্রাকচার ও নোটিফিকেশন সহ)
  Future<void> sendMessage(String receiverID, String message, {String? senderCustomuID}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    final String currentAuthId = currentUser.uid; // লম্বা uID
    final Timestamp timestamp = Timestamp.now();

    // মেসেজ ডাটা
    Map<String, dynamic> newMessage = {
      'senderAuthId': currentAuthId,
      'senderuID': senderCustomuID ?? "", // আপনার ৬-ডিজিটের আইডি (যেমন: 153530)
      'receiverId': receiverID,
      'message': message,
      'timestamp': timestamp,
      'isRead': false,
    };

    // ইউনিক চ্যাট রুম আইডি তৈরি (A_B ফরম্যাট)
    List<String> ids = [currentAuthId, receiverID];
    ids.sort(); 
    String chatRoomId = ids.join("_");

    try {
      // ১. ডাটাবেসে মেসেজ সেভ করা (আপনার স্ক্রিনশটের 'chats' বা 'chat_rooms' অনুযায়ী)
      await _firestore
          .collection('chats') // স্ক্রিনশটে 'chats' কালেকশন দেখা যাচ্ছে
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage);

      // ২. নোটিফিকেশন পাঠানোর লজিক
      // আপনার স্ক্রিনশট অনুযায়ী 'users' কালেকশন থেকে ডাটা আনা হচ্ছে
      DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(receiverID).get();
      DocumentSnapshot senderDoc = await _firestore.collection('users').doc(currentAuthId).get();

      if (receiverDoc.exists) {
        // ফায়ারবেস থেকে fcmToken এবং ইউজারের নাম (name) সংগ্রহ
        String? token = receiverDoc.get('fcmToken'); 
        String senderName = senderDoc.get('name') ?? "নতুন মেসেজ"; // স্ক্রিনশটে ফিল্ডের নাম 'name'

        if (token != null && token.isNotEmpty) {
          await NotificationService.sendNotificationToUser(
            receiverToken: token, 
            title: senderName, 
            body: message,
            extraData: {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'senderId': currentAuthId,
              'route': '/chat',
            },
          );
        }
      }
    } catch (e) {
      print("❌ Chat Service Error: $e");
    }
  }

  // ২. মেসেজ রিসিভ করার রিয়েল-টাইম স্ট্রিম
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // ৩. ইউজারের তথ্য সরাসরি 'users' কালেকশন থেকে পাওয়ার রাস্তা (স্ক্রিনশট অনুযায়ী)
  DocumentReference getUserReference(String uID) {
    return _firestore.collection('users').doc(uID);
  }
}
