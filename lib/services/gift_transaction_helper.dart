import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GiftTransactionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> processGiftTransaction({
    required String senderId,
    required String receiverId,
    required int totalPrice,
    required bool isFree,
    required String giftName,
  }) async {
    try {
      // যদি ফ্রি গিফট না হয় এবং দাম ০ এর বেশি হয়
      if (!isFree && totalPrice > 0) {
        
        // ভাগের হিসাব এখানেই করে ফেলছি যেন অন্য ফাইল না লাগে
        int userShare = (totalPrice * 0.40).floor(); // ৪০% গ্রহীতা পাবে
        int ownerShare = (totalPrice * 0.10).floor(); // ১০% মালিক পাবে

        WriteBatch batch = _firestore.batch();

        // ১. দাতার (Sender) ডায়মন্ড মাইনাস
        DocumentReference senderRef = _firestore.collection('users').doc(senderId);
        batch.update(senderRef, {
          'diamonds': FieldValue.increment(-totalPrice),
        });

        // ২. গ্রহীতার (Receiver) ডায়মন্ড যোগ (৪০%)
        DocumentReference receiverRef = _firestore.collection('users').doc(receiverId);
        batch.update(receiverRef, {
          'diamonds': FieldValue.increment(userShare),
        });

        // ৩. এডমিন স্ট্যাটসে কমিশন রেকর্ড (১০%)
        DocumentReference adminRef = _firestore.collection('admin_stats').doc('revenue');
        batch.set(adminRef, {
          'ownerCommission': FieldValue.increment(ownerShare),
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ৪. গিফট লগ সেভ করা
        DocumentReference logRef = _firestore.collection('gift_logs').doc();
        batch.set(logRef, {
          'senderId': senderId,
          'receiverId': receiverId,
          'giftName': giftName,
          'totalPrice': totalPrice,
          'isFree': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      }
    } catch (e) {
      debugPrint("Gift Transaction Error: $e");
    }
  }
}
