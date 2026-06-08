import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GiftTransactionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> processGiftTransaction({
    required String senderId,
    required String receiverId,
    required String roomId,
    String senderImage = "", // এই লাইনটি যোগ করুন
    String receiverImage = "", // এই লাইনটি যোগ করুন
    required int totalPrice,
    required bool isFree,
    required String giftName,
  }) async {
    try {
      // ✅ ১. আইডি চেক লজিক আপডেট
      if (senderId.isEmpty || receiverId.isEmpty) {
        debugPrint("Transaction Cancelled: Sender or Receiver ID is missing.");
        return;
      }

      WriteBatch batch = _firestore.batch();

      // ২. যদি পেইড গিফট হয়
      if (!isFree && totalPrice > 0) {
        // দাতার (Sender) ডায়মন্ড মাইনাস
        DocumentReference senderRef =
            _firestore.collection('users').doc(senderId);
        batch.update(senderRef, {
          'diamonds': FieldValue.increment(-totalPrice),
        });

        // ✅ ৩. রিসিভার যদি কোনো নির্দিষ্ট ইউজার হয় (All Room/Mic না হয়)
        if (receiverId != "All Room" && receiverId != "All Mic") {
          int userShare = (totalPrice * 0.40).floor(); // ৪০% গ্রহীতা পাবে

          DocumentReference receiverRef =
              _firestore.collection('users').doc(receiverId);
          batch.update(receiverRef, {
            'diamonds': FieldValue.increment(userShare),
          });
          debugPrint("Receiver ($receiverId) received $userShare diamonds");
        }

        // ৪. রুমের মালিকের কমিশন (১০%)
        int ownerShare = (totalPrice * 0.10).floor();
        var roomDoc = await _firestore.collection('rooms').doc(roomId).get();

        if (roomDoc.exists) {
          String? ownerId = roomDoc.data()?['ownerId'];
          if (ownerId != null && ownerId.isNotEmpty) {
            DocumentReference ownerRef =
                _firestore.collection('users').doc(ownerId);
            batch.update(ownerRef, {
              'diamonds': FieldValue.increment(ownerShare),
            });
            debugPrint("Room Owner ($ownerId) received $ownerShare diamonds");
          }
        }
      }

      // ৫. গিফট লগ সেভ করা
      DocumentReference logRef = _firestore.collection('gift_logs').doc();
      batch.set(logRef, {
        'senderId': senderId,
        'receiverId': receiverId,
        'roomId': roomId,
        'senderImage': senderImage, // ডাটাবেজে ছবি সেভ হবে
        'receiverImage': receiverImage, // ডাটাবেজে ছবি সেভ হবে
        'giftName': giftName,
        'totalPrice': totalPrice,
        'isFree': isFree,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      rethrow; // মেইন ফাইলে এরর পাঠানোর জন্য
    }
  }
}
